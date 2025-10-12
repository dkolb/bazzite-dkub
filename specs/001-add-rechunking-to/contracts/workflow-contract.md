# Workflow Contract: GitHub Actions Rechunking Pipeline

**Feature**: Add Rechunking to Reduce Update Sizes  
**Date**: 2025-10-11  
**Contract Type**: GitHub Actions Workflow Interface

## Contract Overview

This document specifies the interface contract for the rechunking-enhanced GitHub Actions workflow. It defines inputs, outputs, step sequencing, error handling, and success criteria for the `.github/workflows/build.yml` modifications.

## Workflow Inputs

### Manual Dispatch Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `fresh-rechunk` | boolean | No | `false` | Enable fresh rechunking mode (omit prev-ref for clean optimization). Set to `true` for monthly maintenance (1st of month) or major version releases. |

**Example Usage**:
```yaml
on:
  workflow_dispatch:
    inputs:
      fresh-rechunk:
        description: 'Enable fresh rechunking mode (omit prev-ref for clean optimization)'
        required: false
        default: false
        type: boolean
```

### Automatic Trigger Inputs

| Trigger | Conditions | fresh-rechunk Value |
|---------|-----------|---------------------|
| Push to `main` | Code changes, package updates | `false` (incremental) |
| Pull Request | Testing builds | `false` (incremental) |
| Schedule (if configured) | Nightly/periodic builds | `false` (incremental) |

## Workflow Steps Contract

### Step 1: Build Image (Existing - No Changes)

**Responsibility**: Build base container image using Containerfile

**Inputs**:
- Containerfile
- build_files/build.sh
- build_files/files/**

**Outputs**:
- Local image: `localhost/bazzite-dkub:<tag>`
- Image available in Podman storage

**Success Criteria**:
- Image builds without errors
- Image tagged with all metadata-action tags
- Image includes all required OCI labels

**Error Handling**:
- Build failure → workflow fails (existing behavior, no changes)

**Timeout**: 15 minutes (existing)

---

### Step 2: Mount BTRFS Storage for Rechunking

**Responsibility**: Create and mount 50GB BTRFS filesystem for rechunking intermediate storage

**Implementation**:
```yaml
- name: Mount BTRFS Storage for Rechunking
  run: |
    sudo mkdir -p /var/tmp/rechunk-btrfs
    sudo truncate -s 50G /var/tmp/rechunk.img
    sudo mkfs.btrfs /var/tmp/rechunk.img
    sudo mount -o loop /var/tmp/rechunk.img /var/tmp/rechunk-btrfs
    sudo chmod 777 /var/tmp/rechunk-btrfs
```

**Inputs**:
- None (uses GitHub Actions runner resources)

**Outputs**:
- BTRFS filesystem mounted at `/var/tmp/rechunk-btrfs`
- Filesystem writable (777 permissions)

**Success Criteria**:
- Mount succeeds without errors
- `/var/tmp/rechunk-btrfs` directory exists and is writable
- Filesystem type is BTRFS (verified by `mount | grep btrfs`)

**Error Scenarios**:
- **Insufficient disk space**: Runner has <60 GB free
  - Error message: "No space left on device"
  - Resolution: Fail workflow with clear error
- **BTRFS tools unavailable**: mkfs.btrfs not found
  - Error message: "mkfs.btrfs: command not found"
  - Resolution: Fail workflow (should not occur on ubuntu-latest)
- **Mount failure**: Loopback mount fails
  - Error message: "mount: failed to setup loop device"
  - Resolution: Fail workflow with troubleshooting guidance

**Timeout**: 2 minutes

**Cleanup**: Automatic (GitHub Actions runner teardown unmounts and deletes)

---

### Step 3: Generate Version Tag

**Responsibility**: Create semantic version tag in format `40-YYYYMMDD`

**Implementation**:
```yaml
- name: Generate Version Tag
  id: generate-version
  run: |
    TAG="40-$(date +%Y%m%d)"
    echo "tag=$TAG" >> $GITHUB_OUTPUT
    echo "Generated version tag: $TAG"
```

**Inputs**:
- Current date from `date` command

**Outputs**:
- Step output `tag`: Version tag string (e.g., "40-20251011")

**Success Criteria**:
- Tag matches pattern `^40-[0-9]{8}$`
- Tag includes 4-digit year (CLARIFICATION: YYYYMMDD, not YYMMDD)
- Tag is unique for current date

**Error Scenarios**:
- **Date command failure**: Unlikely on Linux
  - Resolution: Fail workflow
- **Invalid tag format**: Regex validation can be added if needed
  - Resolution: Fail workflow with format error

**Timeout**: 10 seconds

**Example Output**: `40-20251011` for October 11, 2025

---

### Step 4: Generate Previous Reference

**Responsibility**: Query GHCR for latest published rechunked image tag to use as baseline for incremental rechunking

**Implementation**:
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

**Inputs**:
- `github.event.inputs.fresh-rechunk` (workflow dispatch parameter)
- `steps.generate-version.outputs.tag` (current build tag)
- GHCR repository: `ghcr.io/dkolb/bazzite-dkub`

**Outputs**:
- Step output `ref`: Full image reference (e.g., "ghcr.io/dkolb/bazzite-dkub:40-20251010") OR empty string
- Step output `tag`: Tag only (e.g., "40-20251010") OR empty string

**Success Criteria**:
- If fresh-rechunk=true: Outputs are empty (expected)
- If incremental mode and prev-ref found: Outputs contain valid reference
- If incremental mode and no prev-ref: Outputs are empty (falls back to fresh)

**Error Scenarios**:
- **GHCR query failure** (network error, auth failure):
  - Fallback: Return empty ref (fresh rechunking)
  - Log warning but continue workflow
- **No tags found** (first rechunked build):
  - Expected scenario: Return empty ref
  - Log informational message
- **Concurrent builds** (CLARIFICATION: accepted limitation):
  - Race condition: Two builds query simultaneously
  - Impact: Both might use same prev-ref (suboptimal but valid)
  - Resolution: Document as known limitation, rare occurrence

**Timeout**: 1 minute

**GHCR Query Algorithm** (from research Decision 5):
1. Check fresh-rechunk input → skip if true
2. Query all tags with `skopeo list-tags`
3. Filter tags matching `^40-[0-9]{8}$` regex
4. Sort lexicographically (date-based tags sort correctly)
5. Take last tag (most recent date)
6. Validate tag ≠ current build tag
7. Return full reference or empty

**Rationale** (CLARIFICATION from spec session):
- Replaces brittle date arithmetic approach (`date -d "yesterday"`)
- Handles irregular build schedules (weekends, CI failures, multi-day gaps)
- Queries source of truth (GHCR) rather than calculating expected state
- Robust to build schedule changes

---

### Step 5: Run Rechunker

**Responsibility**: Execute hhd-dev/rechunk GitHub Action to optimize OCI image layers

**Implementation**:
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

**Inputs**:
- `rechunk`: Rechunking tool image reference (v1.2.4)
- `ref`: Local pre-rechunk image reference
- `prev-ref`: Previous rechunked image reference (empty if fresh mode)
- `version`: Version tag for output image
- `labels`: OCI labels to apply (JSON object from metadata step)

**Outputs**:
- Step output `ref`: Rechunked image OCI directory reference (e.g., "oci:/var/tmp/rechunk-output/...")
- Step output `output`: Output directory path
- Rechunked image with optimized layers
- OCI labels including `rechunk.*` metadata

**Success Criteria**:
- Rechunking completes without errors
- Output image includes all input labels plus rechunking metadata
- Chunk count is positive integer (typically 7-10)
- If prev-ref provided: Incremental optimization applied
- If prev-ref empty: Fresh optimization applied

**Error Scenarios**:
- **BTRFS mount unavailable**:
  - Error: "BTRFS filesystem not found at /var/tmp/rechunk-btrfs"
  - Resolution: Fail workflow (Step 2 should have caught this)
- **Input image not found**:
  - Error: "Image localhost/bazzite-dkub:... not found"
  - Resolution: Fail workflow (Step 1 should have succeeded)
- **Rechunking timeout** (>10 minutes):
  - Error: Workflow step timeout
  - Resolution: Fail workflow, investigate performance issue
- **Prev-ref image unavailable** (deleted from GHCR):
  - Rechunk action should fall back to fresh mode
  - May log warning but continue
- **Insufficient BTRFS space**:
  - Error: "No space left on device"
  - Resolution: Fail workflow, increase BTRFS size in Step 2

**Timeout**: 10 minutes (enforced by `timeout-minutes`)

**Performance Expectations**:
- Fresh rechunking: 5-7 minutes
- Incremental rechunking: 2-3 minutes
- Target: <8 minutes (SC-002)

**Output Validation**:
- Check `rechunk.version` label exists
- Check `rechunk.chunks` label is positive integer
- If incremental: Check `rechunk.prev-ref` label matches input

---

### Step 6: Load Rechunked Image and Tag

**Responsibility**: Pull rechunked image from OCI directory into Podman storage and apply all tags

**Implementation**:
```yaml
- name: Load rechunked image in podman and tag
  run: |
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

**Inputs**:
- `steps.rechunk.outputs.ref`: Rechunked image OCI directory reference
- `steps.rechunk.outputs.output`: Output directory to clean up
- `steps.metadata.outputs.tags`: All tags to apply (newline or space-separated)

**Outputs**:
- Rechunked image loaded into Podman storage
- Image tagged with all required tags (latest, 40, 40-YYYYMMDD, etc.)
- Temporary OCI directory cleaned up

**Success Criteria**:
- `podman pull` succeeds
- All tags applied without errors
- Image available for push step

**Error Scenarios**:
- **Pull failure**: OCI directory corrupted or incomplete
  - Resolution: Fail workflow
- **Tag failure**: Invalid tag format
  - Resolution: Fail workflow
- **Cleanup failure**: Permission error on rm
  - Resolution: Log warning, continue (not critical)

**Timeout**: 5 minutes

**Tag Examples**:
- `ghcr.io/dkolb/bazzite-dkub:latest`
- `ghcr.io/dkolb/bazzite-dkub:40`
- `ghcr.io/dkolb/bazzite-dkub:40-20251011`

---

### Step 7: Push to GHCR (Existing - Minimal Changes)

**Responsibility**: Push rechunked image to GitHub Container Registry

**Implementation**: Existing push step, no changes needed. Pushes all tags applied in Step 6.

**Inputs**:
- Rechunked image in Podman storage (from Step 6)
- All tags from metadata step
- GITHUB_TOKEN for authentication

**Outputs**:
- Image published to `ghcr.io/dkolb/bazzite-dkub` with all tags
- Image layers uploaded to GHCR

**Success Criteria**:
- All tags pushed successfully
- Image manifest includes all OCI labels (standard + rechunking metadata)
- Image accessible via `docker pull` or `skopeo inspect`

**Error Scenarios**:
- **Authentication failure**: GITHUB_TOKEN invalid or insufficient permissions
  - Resolution: Fail workflow
- **Network failure**: GHCR unavailable
  - Resolution: Fail workflow (retryable by re-running workflow)
- **Storage quota exceeded**: GHCR storage limit reached
  - Resolution: Fail workflow, clean up old images

**Timeout**: 10 minutes (existing)

**CLARIFICATION**: Tag retention policy is indefinite (keep all tags, clean up manually if needed)

---

### Step 8: Sign with Cosign (Existing - No Changes)

**Responsibility**: Sign rechunked image with Cosign using private key

**Implementation**: Existing Cosign signing step, no changes needed. Signs rechunked image.

**Inputs**:
- Rechunked image in GHCR (from Step 7)
- COSIGN_PRIVATE_KEY secret

**Outputs**:
- Cosign signature attached to image in GHCR
- Signature verifiable with public key (`cosign.pub`)

**Success Criteria**:
- Signing completes without errors
- Signature verifiable: `cosign verify --key cosign.pub ghcr.io/dkolb/bazzite-dkub:<tag>`

**Error Scenarios**:
- **Private key unavailable**: COSIGN_PRIVATE_KEY secret not set
  - Resolution: Fail workflow
- **Signing failure**: Key format invalid, image not found
  - Resolution: Fail workflow

**Timeout**: 2 minutes (existing)

**CLARIFICATION from spec session**: Cosign verification NOT added to acceptance tests. Trust existing integration, document in troubleshooting.

---

## Workflow Sequencing Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│ Trigger: Push / PR / Dispatch (fresh-rechunk param)            │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│ Step 1: Build Image (EXISTING)                                 │
│ Output: localhost/bazzite-dkub:<tag>                            │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│ Step 2: Mount BTRFS Storage (NEW)                               │
│ Output: /var/tmp/rechunk-btrfs (50GB)                           │
│ Timeout: 2 min | Fail-fast: Yes                                │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│ Step 3: Generate Version Tag (NEW)                              │
│ Output: tag=40-YYYYMMDD                                         │
│ Timeout: 10 sec | Fail-fast: Yes                               │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│ Step 4: Generate Previous Reference (NEW)                       │
│ Logic: GHCR query with skopeo + jq                              │
│ Output: ref=ghcr.io/dkolb/bazzite-dkub:<prev-tag> OR empty     │
│ Fallback: Empty ref → fresh rechunking                          │
│ Timeout: 1 min | Fail-fast: No (fallback on error)            │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│ Step 5: Run Rechunker (NEW)                                     │
│ Action: hhd-dev/rechunk@5fbe1d3a (v1.2.4 pinned)                │
│ Inputs: ref, prev-ref, version, labels                          │
│ Output: Rechunked OCI directory                                 │
│ Timeout: 10 min | Fail-fast: Yes                               │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│ Step 6: Load Rechunked Image (NEW)                              │
│ Logic: podman pull + tag all metadata tags                      │
│ Output: Rechunked image in Podman storage                       │
│ Timeout: 5 min | Fail-fast: Yes                                │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│ Step 7: Push to GHCR (EXISTING - minimal changes)               │
│ Output: Image published with all tags                           │
│ Timeout: 10 min | Fail-fast: Yes                               │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│ Step 8: Sign with Cosign (EXISTING - no changes)                │
│ Output: Signed image in GHCR                                    │
│ Timeout: 2 min | Fail-fast: Yes                                │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
                  ┌──────┴──────┐
                  │   SUCCESS   │
                  └─────────────┘
```

## Error Handling Strategy

### Fail-Fast Principle

All steps (except Step 4 prev-ref query) use fail-fast error handling:
- Step failure → Workflow fails
- No partial images published
- Clear error messages in logs

**Rationale**: Immutable systems require known-good images. Publishing corrupted or partially rechunked images could break user systems.

### Fallback Scenarios

**Step 4 Only**: Prev-ref generation has graceful fallback:
- GHCR query failure → empty ref → fresh rechunking
- No tags found → empty ref → fresh rechunking
- Tag matches current → empty ref → fresh rechunking

All other scenarios fail the workflow.

### Error Recovery

**Manual Recovery**:
- Workflow failure → Review logs → Fix issue → Re-run workflow
- No automated retries (rechunking failures are typically deterministic)

**Rollback**:
- Users can always rollback to previous OSTree deployment
- Failed builds don't publish images, so users never see broken versions

## Success Criteria Validation

### SC-001: 5-10x Download Reduction
- **Validation**: Manual VM testing (deploy rechunked image, make trivial change, rebuild, measure update download via `rpm-ostree upgrade --check`)
- **Expected**: 200-400 MB download vs. ~2 GB baseline

### SC-002: <8 Minutes Rechunking Overhead
- **Validation**: Workflow logs, Step 5 duration
- **Expected**: Fresh rechunking 5-7 min, incremental 2-3 min

### SC-003: 100% Build Success Rate
- **Validation**: Monitor workflow runs over 30 days
- **Expected**: No failures due to rechunking (other failures acceptable)

### SC-005: OCI Labels Present
- **Validation**: `skopeo inspect docker://ghcr.io/dkolb/bazzite-dkub:latest | jq '.Labels'`
- **Expected**: All standard labels + `rechunk.version`, `rechunk.chunks`, optionally `rechunk.prev-ref`

### SC-010: Logs Include Statistics
- **Validation**: Workflow logs from Step 5 (rechunk action output)
- **Expected**: Chunk count, prev-ref used, duration visible in logs

## Timeout Policies

| Step | Timeout | Rationale |
|------|---------|-----------|
| Step 2: Mount BTRFS | 2 min | Filesystem operations are fast, long timeout indicates failure |
| Step 3: Generate Version | 10 sec | Date command is instant, excessive timeout unnecessary |
| Step 4: Prev-ref Query | 1 min | GHCR API query + jq processing, generous timeout for network latency |
| Step 5: Run Rechunker | 10 min | Rechunking is CPU/IO intensive, 10 min covers worst case |
| Step 6: Load Image | 5 min | Podman pull + tagging, should be fast (<2 min typical) |

**Total workflow timeout**: None at workflow level. Individual step timeouts provide granular control.

## Contract Validation

### Pre-Execution Validation

- [ ] BTRFS tools available on runner (mkfs.btrfs, mount)
- [ ] Sufficient disk space (>60 GB free)
- [ ] skopeo and jq installed (for prev-ref query)
- [ ] GITHUB_TOKEN has packages:write permission
- [ ] COSIGN_PRIVATE_KEY secret configured

### Post-Execution Validation

- [ ] Rechunked image published to GHCR
- [ ] All tags applied (latest, 40, 40-YYYYMMDD)
- [ ] OCI labels include rechunking metadata
- [ ] Cosign signature attached and verifiable
- [ ] Workflow logs include rechunking statistics

## Version Compatibility

- **hhd-dev/rechunk**: v1.2.4 (pinned SHA: 5fbe1d3a639615d2548d83bc888360de6267b1a2)
- **GitHub Actions runner**: ubuntu-latest (includes BTRFS, skopeo, jq)
- **Podman/Buildah**: Version provided by ubuntu-latest runner
- **skopeo**: Version provided by ubuntu-latest runner (≥1.9 for OCI support)
- **jq**: Version provided by ubuntu-latest runner (≥1.6 for regex support)

## Monitoring and Observability

**Workflow Logs Should Include**:
- Version tag generated (Step 3 output)
- Prev-ref used or "fresh rechunking" message (Step 4 output)
- Rechunking duration (Step 5 timing)
- Chunk count created (Step 5 logs from hhd-dev/rechunk)
- Tags applied (Step 6 logs)
- Push success confirmation (Step 7 logs)
- Signature creation confirmation (Step 8 logs)

**Metrics to Track** (post-deployment):
- Workflow success rate (SC-003 validation)
- Rechunking duration trends (SC-002 validation)
- Image size trends (downloaded sizes from end users)

## Contract Change Management

**Breaking Changes**:
- Changing tag format (40-YYYYMMDD)
- Changing OCI label schema
- Upgrading hhd-dev/rechunk to version with incompatible changes

**Non-Breaking Changes**:
- Adjusting timeouts
- Improving error messages
- Adding optional labels
- Optimizing BTRFS size

**Deprecation Process**:
1. Announce in commit message
2. Update documentation
3. Provide migration period (if applicable)
4. Monitor for issues

## Summary

This contract defines a robust, fail-fast rechunking pipeline with:
- ✅ 8 sequential steps (1 existing build, 5 new rechunking, 2 existing push/sign)
- ✅ Clear input/output contracts for each step
- ✅ Graceful fallback for prev-ref generation (only step with non-fail-fast behavior)
- ✅ Comprehensive error handling and timeout policies
- ✅ Success criteria validation mapped to spec SC-001, SC-002, SC-003, SC-005, SC-010
- ✅ Incorporates all clarifications from spec session (GHCR query, monthly fresh schedule, tag format, concurrent builds, Cosign approach)

**Implementation Readiness**: This contract is directly implementable in `.github/workflows/build.yml` with minimal adaptation. All technical decisions from research phase are encoded in step specifications.
