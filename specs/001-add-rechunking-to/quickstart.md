# Quickstart: Implement Rechunking Integration

**Feature**: Add Rechunking to Reduce Update Sizes  
**Date**: 2025-10-11  
**Estimated Time**: 2-3 hours  
**Difficulty**: Moderate (GitHub Actions workflow modification)

## Overview

This guide provides step-by-step instructions to integrate hhd-dev/rechunk into the bazzite-dkub build pipeline. Follow these 7 steps sequentially to implement, test, and deploy rechunking.

**Prerequisites**:
- Local development machine with git, actionlint, skopeo, jq installed
- GitHub repository access (write permissions)
- Access to GitHub Actions workflow dispatch
- Test VM or ability to build QCOW2 images for validation

**Quick Navigation**:
1. [Modify Workflow](#step-1-modify-github-actions-workflow)
2. [Test Locally](#step-2-test-workflow-syntax-locally)
3. [Trigger First Build](#step-3-trigger-first-rechunked-build)
4. [Verify Image](#step-4-verify-rechunked-image-properties)
5. [Test Incremental](#step-5-test-incremental-rechunking)
6. [Deploy and Measure](#step-6-deploy-to-vm-and-measure-update-size)
7. [Update Documentation](#step-7-update-documentation)

---

## Step 1: Modify GitHub Actions Workflow

**Goal**: Add rechunking steps to `.github/workflows/build.yml`

### 1.1: Add Workflow Dispatch Input

**Location**: Top of file, in `on:` triggers section

**Add**:
```yaml
on:
  push:
    branches:
      - main
    paths:
      - 'Containerfile'
      - 'build_files/**'
      # ... existing paths ...
  pull_request:
  # ADD THIS SECTION:
  workflow_dispatch:
    inputs:
      fresh-rechunk:
        description: 'Enable fresh rechunking mode (omit prev-ref for clean optimization)'
        required: false
        default: false
        type: boolean
```

**Validation**: Ensure proper YAML indentation (workflow_dispatch at same level as push/pull_request)

---

### 1.2: Add BTRFS Mount Step

**Location**: After "Build Image" step (typically after `buildah` or `podman build` step)

**Add**:
```yaml
    - name: Mount BTRFS Storage for Rechunking
      run: |
        echo "Creating 50GB BTRFS filesystem for rechunking..."
        sudo mkdir -p /var/tmp/rechunk-btrfs
        sudo truncate -s 50G /var/tmp/rechunk.img
        sudo mkfs.btrfs /var/tmp/rechunk.img
        sudo mount -o loop /var/tmp/rechunk.img /var/tmp/rechunk-btrfs
        sudo chmod 777 /var/tmp/rechunk-btrfs
        echo "BTRFS mounted at /var/tmp/rechunk-btrfs"
        df -h /var/tmp/rechunk-btrfs
```

**Validation**: Check that `sudo` is available (GitHub Actions ubuntu-latest includes it)

---

### 1.3: Add Version Tag Generation Step

**Location**: After BTRFS mount step

**Add**:
```yaml
    - name: Generate Version Tag
      id: generate-version
      run: |
        TAG="40-$(date +%Y%m%d)"
        echo "tag=$TAG" >> $GITHUB_OUTPUT
        echo "Generated version tag: $TAG"
```

**Note**: Ensure step has `id: generate-version` for reference in later steps

---

### 1.4: Add Previous Reference Generation Step

**Location**: After version tag generation

**Add**:
```yaml
    - name: Generate Previous Reference
      id: generate-prev-ref
      run: |
        # Skip prev-ref if fresh-rechunk mode enabled
        if [[ "${{ github.event.inputs.fresh-rechunk }}" == "true" ]]; then
          echo "Fresh rechunking mode enabled - skipping prev-ref"
          echo "ref=" >> $GITHUB_OUTPUT
          echo "tag=" >> $GITHUB_OUTPUT
          exit 0
        fi
        
        # Query GHCR for latest tag matching Fedora 40 date pattern (40-YYYYMMDD)
        echo "Querying GHCR for latest rechunked image..."
        LATEST_TAG=$(skopeo list-tags docker://ghcr.io/dkolb/bazzite-dkub 2>/dev/null | \
          jq -r '.Tags | map(select(test("^40-[0-9]{8}$"))) | sort | last // ""')
        
        # Validate tag exists and is not current build's tag (prevent circular reference)
        CURRENT_TAG="${{ steps.generate-version.outputs.tag }}"
        if [[ -n "$LATEST_TAG" ]] && [[ "$LATEST_TAG" != "$CURRENT_TAG" ]]; then
          echo "Using prev-ref: ghcr.io/dkolb/bazzite-dkub:$LATEST_TAG"
          echo "ref=ghcr.io/dkolb/bazzite-dkub:$LATEST_TAG" >> $GITHUB_OUTPUT
          echo "tag=$LATEST_TAG" >> $GITHUB_OUTPUT
        else
          echo "No valid prev-ref found - using fresh rechunking"
          if [[ "$LATEST_TAG" == "$CURRENT_TAG" ]]; then
            echo "Reason: Latest tag matches current build tag (same-day rebuild)"
          else
            echo "Reason: No previous rechunked images found (first build)"
          fi
          echo "ref=" >> $GITHUB_OUTPUT
          echo "tag=" >> $GITHUB_OUTPUT
        fi
```

**Note**: Ensure `skopeo` and `jq` are available (GitHub Actions ubuntu-latest includes both)

---

### 1.5: Add Rechunking Step

**Location**: After previous reference generation, BEFORE "Push to GHCR" step

**Add**:
```yaml
    - name: Run Rechunker
      id: rechunk
      uses: hhd-dev/rechunk@5fbe1d3a639615d2548d83bc888360de6267b1a2  # v1.2.4 pinned SHA
      with:
        rechunk: 'ghcr.io/hhd-dev/rechunk:v1.2.4'
        ref: "localhost/${{ env.IMAGE_NAME }}:${{ env.DEFAULT_TAG }}"
        prev-ref: '${{ steps.generate-prev-ref.outputs.ref }}'
        version: '${{ steps.generate-version.outputs.tag }}'
        labels: ${{ steps.metadata.outputs.labels }}
      timeout-minutes: 10
```

**Important**: 
- Replace `${{ env.IMAGE_NAME }}` with actual image name if `IMAGE_NAME` env var not set
- Replace `${{ env.DEFAULT_TAG }}` with actual tag or use metadata step output
- Ensure `steps.metadata` exists and produces labels output

---

### 1.6: Add Rechunked Image Load Step

**Location**: Immediately after rechunking step

**Add**:
```yaml
    - name: Load rechunked image in podman and tag
      run: |
        echo "Loading rechunked image from OCI directory..."
        IMAGE=$(podman pull ${{ steps.rechunk.outputs.ref }})
        echo "Loaded rechunked image: $IMAGE"
        
        # Clean up rechunk temporary output directory
        sudo rm -rf ${{ steps.rechunk.outputs.output }}
        
        # Tag rechunked image with all tags from metadata step
        for tag in ${{ steps.metadata.outputs.tags }}; do
          echo "Tagging as: $tag"
          podman tag $IMAGE $tag
        done
        
        echo "Rechunked image ready for push"
```

**Note**: This step replaces the built image with the rechunked version before push

---

### 1.7: Verify Push and Sign Steps

**Location**: After load step

**Verify**: Existing "Push to GHCR" and "Sign with Cosign" steps should work unchanged. They will now push and sign the rechunked image instead of the original build.

**No changes needed** to push/sign steps.

---

## Step 2: Test Workflow Syntax Locally

**Goal**: Validate workflow syntax before pushing to GitHub

### 2.1: Install actionlint

```bash
# macOS
brew install actionlint

# Linux (download binary)
curl -LO https://github.com/rhysd/actionlint/releases/latest/download/actionlint_linux_amd64.tar.gz
tar xzf actionlint_linux_amd64.tar.gz
sudo mv actionlint /usr/local/bin/
```

### 2.2: Run Syntax Validation

```bash
cd /path/to/bazzite-dkub
actionlint .github/workflows/build.yml
```

**Expected Output**: No errors (or only warnings about shellcheck if not installed)

### 2.3: Fix Any Errors

Common errors:
- **Indentation issues**: Ensure all new steps are properly indented under `jobs.<job-name>.steps`
- **Undefined step IDs**: Verify `generate-version`, `generate-prev-ref`, `rechunk` step IDs are correct
- **Missing `${{ }}` syntax**: Ensure all variable references use GitHub Actions expression syntax

---

## Step 3: Trigger First Rechunked Build

**Goal**: Build first rechunked image using fresh mode (no prev-ref)

### 3.1: Push Workflow Changes

```bash
git add .github/workflows/build.yml
git commit -m "feat: integrate hhd-dev/rechunk for 5-10x update size reduction"
git push origin 001-add-rechunking-to  # Or your feature branch
```

### 3.2: Create Pull Request or Merge to Main

**Option A**: Create PR and trigger via PR build (fresh-rechunk=false by default)
**Option B**: Merge to main and trigger via push (fresh-rechunk=false by default)
**Option C**: Use workflow dispatch for more control (recommended for first build)

### 3.3: Trigger via Workflow Dispatch (Recommended)

1. Go to: `https://github.com/dkolb/bazzite-dkub/actions/workflows/build.yml`
2. Click "Run workflow" button
3. Select branch: `main` (or feature branch if testing)
4. Set `fresh-rechunk`: **true** (important for first build, no prev-ref exists)
5. Click "Run workflow"

### 3.4: Monitor Workflow Execution

**Watch for**:
- ✅ BTRFS mount succeeds (~10 seconds)
- ✅ Version tag generated (e.g., `40-20251011`)
- ✅ Prev-ref generation returns empty (first build)
- ✅ Rechunking completes in 5-7 minutes (fresh mode)
- ✅ Image pushed to GHCR with all tags
- ✅ Cosign signing succeeds

**Expected Duration**: 12-18 minutes total (build 8-10 min + rechunk 5-7 min + push/sign 2-3 min)

### 3.5: Handle Failures

**Common issues**:

| Error | Cause | Solution |
|-------|-------|----------|
| "mkfs.btrfs: command not found" | BTRFS tools missing | Unlikely on ubuntu-latest; verify runner image |
| "No space left on device" | Insufficient disk space | Check runner has >60 GB free; reduce BTRFS size if needed |
| "Image localhost/bazzite-dkub:... not found" | Build step failed before rechunking | Fix build errors first |
| "timeout" during rechunking | Slow rechunking (>10 min) | Investigate performance; may need to increase timeout |

---

## Step 4: Verify Rechunked Image Properties

**Goal**: Confirm rechunked image includes correct OCI labels and metadata

### 4.1: Inspect Image with Skopeo

```bash
# Get current date tag (adjust date as needed)
TAG="40-$(date +%Y%m%d)"

# Inspect image
skopeo inspect docker://ghcr.io/dkolb/bazzite-dkub:$TAG | jq
```

### 4.2: Verify Required Labels

**Check for**:
```bash
# Standard OCI labels
skopeo inspect docker://ghcr.io/dkolb/bazzite-dkub:$TAG | jq '.Labels | {
  title: .["org.opencontainers.image.title"],
  version: .["org.opencontainers.image.version"],
  url: .["org.opencontainers.image.url"],
  build_url: .["io.github-actions.build.url"]
}'

# Rechunking metadata
skopeo inspect docker://ghcr.io/dkolb/bazzite-dkub:$TAG | jq '.Labels | {
  rechunk_version: .["rechunk.version"],
  rechunk_chunks: .["rechunk.chunks"],
  rechunk_prev_ref: .["rechunk.prev-ref"]
}'
```

**Expected Output**:
```json
{
  "title": "bazzite-dkub",
  "version": "40-20251011",
  "url": "https://github.com/dkolb/bazzite-dkub",
  "build_url": "https://github.com/dkolb/bazzite-dkub/actions/runs/..."
}

{
  "rechunk_version": "v1.2.4",
  "rechunk_chunks": "7",  // Or 8, 9, 10 - typical range
  "rechunk_prev_ref": ""  // Empty for fresh mode
}
```

### 4.3: Verify Cosign Signature

```bash
cosign verify --key cosign.pub ghcr.io/dkolb/bazzite-dkub:$TAG
```

**Expected Output**: Signature verification success with build info

**If signature fails**: Check Cosign step logs, verify `COSIGN_PRIVATE_KEY` secret is set

---

## Step 5: Test Incremental Rechunking

**Goal**: Validate incremental rechunking with prev-ref

### 5.1: Make Trivial Change

```bash
# Example: Update README.md
echo "<!-- Last updated: $(date) -->" >> README.md
git add README.md
git commit -m "chore: update README timestamp for rechunking test"
git push origin main
```

### 5.2: Trigger Build (Automatic or Manual)

**Option A**: Automatic push trigger (if workflow configured for README changes)
**Option B**: Manual workflow dispatch with `fresh-rechunk: false` (default)

### 5.3: Monitor Prev-Ref Generation

**Check workflow logs** for "Generate Previous Reference" step:

**Expected output**:
```
Querying GHCR for latest rechunked image...
Using prev-ref: ghcr.io/dkolb/bazzite-dkub:40-20251011
```

**Validate**: Prev-ref tag matches yesterday's build (or most recent build)

### 5.4: Monitor Rechunking Duration

**Expected**: 2-3 minutes for incremental rechunking (vs. 5-7 minutes for fresh)

**If slow** (>5 min): Prev-ref may not be working correctly; check logs for fallback to fresh mode

### 5.5: Verify Incremental Image Labels

```bash
TAG="40-$(date +%Y%m%d)"
skopeo inspect docker://ghcr.io/dkolb/bazzite-dkub:$TAG | jq '.Labels["rechunk.prev-ref"]'
```

**Expected**: Non-empty prev-ref value (e.g., `"ghcr.io/dkolb/bazzite-dkub:40-20251010"`)

---

## Step 6: Deploy to VM and Measure Update Size

**Goal**: Validate 5-10x update size reduction (SC-001)

### 6.1: Build QCOW2 VM Image (Optional - First Deployment)

If testing fresh install:

```bash
just build-qcow2
just run-vm-qcow2
```

**Or** use existing bazzite-dkub system.

### 6.2: Rebase to Rechunked Image (Existing System)

On running bazzite-dkub VM or physical machine:

```bash
# Rebase to latest rechunked image
sudo rpm-ostree rebase ghcr.io/dkolb/bazzite-dkub:latest

# Reboot into rechunked deployment
systemctl reboot
```

### 6.3: Verify Rechunked Deployment Booted

After reboot:

```bash
rpm-ostree status
```

**Expected**: Current deployment shows rechunked image version

### 6.4: Make Another Trivial Change and Build

Back on development machine:

```bash
# Make another small change
echo "<!-- Test update: $(date) -->" >> README.md
git add README.md
git commit -m "chore: test update size measurement"
git push origin main

# Wait for build to complete (~12-18 min)
```

### 6.5: Measure Update Download Size

On test VM:

```bash
# Check for available update
sudo rpm-ostree upgrade --check

# Measure download size (dry-run)
sudo rpm-ostree upgrade --preview
```

**Look for**: "Downloading metadata" and layer download sizes in output

**Approximate output**:
```
Receiving objects: 15% (3/20) 87.3 MB/s 215.8 MB
...
Total download size: 248.5 MB
```

**Expected Range**: 200-400 MB for trivial changes (vs. ~2 GB without rechunking)

**Validation**: If download size is >500 MB, rechunking may not be optimal. Check:
- Prev-ref was used (not fresh mode accidentally)
- Previous build completed successfully
- Chunk count is reasonable (7-10)

### 6.6: Complete Update

```bash
# Apply update
sudo rpm-ostree upgrade

# Reboot
systemctl reboot
```

**Verify**: System boots successfully, applications work normally

### 6.7: Test Rollback (Optional)

```bash
# Rollback to previous deployment
sudo rpm-ostree rollback

# Reboot
systemctl reboot
```

**Validation**: Rollback between rechunked versions works seamlessly (SC-007)

---

## Step 7: Update Documentation

**Goal**: Document rechunking feature in README.md and AGENTS.md

### 7.1: Update README.md

**Section**: Customizations (near top)

**Add**:
```markdown
### Update Optimization

- **Rechunking**: Container images are rechunked using hhd-dev/rechunk to reduce update download sizes by 5-10x (from ~2GB to 200-400MB for minor changes). This is completely transparent to users—standard `rpm-ostree upgrade` workflow applies.
```

**Section**: Technical Details

**Add**:
```markdown
### Rechunking

All published images are rechunked during CI/CD to optimize delta downloads. This reduces bandwidth consumption by 80-95% for typical package updates. Rechunking uses incremental optimization by default (comparing to previous published version), with optional fresh rechunking mode for major versions.

**For maintainers**: To trigger fresh rechunking (e.g., for monthly maintenance on 1st of month), use the GitHub Actions workflow dispatch with `fresh-rechunk: true`.

**Troubleshooting**:
- **BTRFS mount errors**: GitHub Actions ubuntu-latest runners include BTRFS by default. If mount fails, check runner disk space (requires >60 GB free).
- **Prev-ref query failures**: If GHCR query fails, rechunking automatically falls back to fresh mode. Check GitHub Actions logs for network errors.
- **Cosign signing after rechunking**: Signing occurs AFTER rechunking, signing the final optimized image. This is expected behavior—rechunked images are signed, not original builds.
```

### 7.2: Update AGENTS.md

**Section**: Current Customizations

**Add**:
```markdown
- Rechunking: hhd-dev/rechunk GitHub Action v1.2.4 integrated into CI/CD pipeline for 5-10x update size reduction
```

**Section**: Development Workflow

**Add new subsection**:
```markdown
### Monthly Maintenance

**Fresh Rechunking Schedule**: On the 1st of each month, trigger a fresh rechunking build to reset chunk optimization:

1. Navigate to: GitHub Actions → Build workflow
2. Click "Run workflow"
3. Select branch: `main`
4. Set `fresh-rechunk: true`
5. Click "Run workflow"
6. Verify build completes successfully and image is published

**Validation**: After fresh rechunk, verify chunk count is reasonable (7-10) via:
```bash
skopeo inspect docker://ghcr.io/dkolb/bazzite-dkub:latest | jq '.Labels["rechunk.chunks"]'
```

**Section**: Troubleshooting

**Add new subsection**:
```markdown
### Rechunking Build Failures

- **BTRFS mount error**: Ensure GitHub Actions runner supports BTRFS (ubuntu-latest includes BTRFS by default). Check runner disk space (needs >60 GB free).
- **Prev-ref not found**: First rechunked build or all previous images deleted—workflow automatically falls back to fresh rechunking. Check logs for "No valid prev-ref found" message.
- **Rechunking timeout**: If exceeds 10 minutes, investigate BTRFS storage performance or consider reducing max-layers parameter (advanced).
- **Cosign signature fails**: Ensure `COSIGN_PRIVATE_KEY` secret is set in GitHub repository. Signature is applied AFTER rechunking to the final optimized image.
```

### 7.3: Commit Documentation

```bash
git add README.md AGENTS.md
git commit -m "docs: document rechunking feature integration and maintenance procedures"
git push origin main
```

---

## Step 8: Monitor Production Builds (Post-Deployment)

**Goal**: Validate SC-003 (100% success rate over 30 days)

### 8.1: Set Up Monitoring

- **GitHub Actions**: Watch workflow runs for rechunking step failures
- **Calendar reminder**: 1st of each month for fresh rechunking trigger
- **Update logs**: Periodically check end-user update sizes via test VM

### 8.2: Success Criteria Checklist

After 30 days of production use:

- [ ] SC-001: Update download sizes reduced 5-10x (verified via VM testing)
- [ ] SC-002: Rechunking overhead <8 minutes (check workflow logs)
- [ ] SC-003: 100% build success rate (no rechunking-related failures)
- [ ] SC-004: VM smoke tests pass (boot, applications work, rpm-ostree operations succeed)
- [ ] SC-005: OCI labels present in all published images
- [ ] SC-006: Bandwidth reduction 80-95% (user feedback or metrics)
- [ ] SC-007: Rollback works between rechunked versions
- [ ] SC-009: Documentation updated in README.md and AGENTS.md
- [ ] SC-010: Workflow logs include rechunking statistics

---

## Troubleshooting Reference

### Quick Diagnosis Commands

```bash
# Check if image is rechunked
skopeo inspect docker://ghcr.io/dkolb/bazzite-dkub:latest | jq '.Labels["rechunk.version"]'

# Verify chunk count
skopeo inspect docker://ghcr.io/dkolb/bazzite-dkub:latest | jq '.Labels["rechunk.chunks"]'

# Check prev-ref used
skopeo inspect docker://ghcr.io/dkolb/bazzite-dkub:latest | jq '.Labels["rechunk.prev-ref"]'

# List all rechunked tags
skopeo list-tags docker://ghcr.io/dkolb/bazzite-dkub | jq '.Tags | map(select(test("^40-[0-9]{8}$")))'

# Verify Cosign signature
cosign verify --key cosign.pub ghcr.io/dkolb/bazzite-dkub:latest

# Check workflow run status
gh run list --workflow=build.yml --limit 5
```

### Common Issues and Solutions

| Issue | Diagnosis | Solution |
|-------|-----------|----------|
| Rechunking takes >10 min | Check BTRFS mount, disk I/O | Increase timeout, investigate runner performance |
| No prev-ref found (expected) | First build or deleted tags | Normal behavior, uses fresh rechunking |
| Prev-ref points to deleted tag | Tag manually deleted from GHCR | Falls back to fresh mode, no action needed |
| Chunk count >15 | Suboptimal chunking | Trigger fresh rechunk to reset |
| Update size not reduced | Prev-ref not used or major changes | Verify prev-ref in labels, check if fresh mode accidentally triggered |
| Signature verification fails | Cosign key mismatch or signing failed | Check COSIGN_PRIVATE_KEY secret, review workflow logs |

---

## Rollback Plan

If rechunking causes issues, rollback procedure:

### Quick Disable (Emergency)

1. Navigate to `.github/workflows/build.yml`
2. Comment out rechunking steps (Step 2-6 from implementation)
3. Commit with message: `fix: temporarily disable rechunking (investigating issue)`
4. Push to main
5. Trigger build to publish non-rechunked image

### Permanent Removal

1. Remove all rechunking steps from workflow
2. Remove workflow_dispatch input for fresh-rechunk
3. Update documentation to remove rechunking references
4. Clean up GHCR tags if needed (manual operation)

### User Impact

- **No breaking changes**: Non-rechunked images work identically to rechunked images
- **Users can rollback**: rpm-ostree rollback works between rechunked and non-rechunked deployments
- **Larger updates**: Users will experience larger downloads (~2 GB) but system remains functional

---

## Success Summary

After completing all steps, you will have:

✅ **Rechunking integrated** into GitHub Actions workflow  
✅ **First rechunked image** published to GHCR  
✅ **Incremental rechunking** validated with prev-ref  
✅ **VM testing** confirms 5-10x update size reduction  
✅ **Documentation** updated for users and maintainers  
✅ **Monthly maintenance** process established  
✅ **Monitoring** in place for ongoing validation  

**Next Steps**:
- Monitor production builds for 30 days (SC-003 validation)
- Trigger fresh rechunking monthly on 1st of month
- Collect user feedback on update experience
- Consider automating fresh rechunking schedule (future enhancement)

---

## Additional Resources

- **hhd-dev/rechunk**: https://github.com/hhd-dev/rechunk
- **Universal Blue Documentation**: https://universal-blue.org/
- **Bazzite Build Workflow**: https://github.com/ublue-os/bazzite/blob/main/.github/workflows/build.yml (lines 315-349 for rechunking reference)
- **OSTree/rpm-ostree**: https://ostreedev.github.io/ostree/
- **Cosign**: https://docs.sigstore.dev/cosign/overview/

**Community Support**:
- Universal Blue Discord: https://discord.gg/universal-blue
- Universal Blue Discourse: https://universal-blue.discourse.group/

---

**Estimated total time**: 2-3 hours (including build wait times). Active work: ~1 hour.
