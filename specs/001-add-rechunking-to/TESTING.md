# Testing Plan: Add Rechunking to Reduce Update Sizes

**Feature Branch**: `001-add-rechunking-to`  
**Date**: 2025-10-11  
**Status**: Ready for Testing

## Testing Overview

This document outlines the testing plan for validating the rechunking implementation. Follow these steps sequentially to verify all functionality.

## Phase 1: Initial Build Testing

### Test 1.1: Trigger First Rechunked Build

**Objective**: Verify rechunking workflow executes successfully on first build (no prev-ref)

**Steps**:
1. Navigate to: https://github.com/dkolb/bazzite-dkub/actions/workflows/build.yml
2. Click "Run workflow"
3. Select branch: `001-add-rechunking-to`
4. Leave `fresh-rechunk` unchecked (default: false)
5. Click "Run workflow"

**Expected Results**:
- Build completes successfully
- Duration: 12-18 minutes (build 8-10 min + rechunk 5-7 min + push 2-3 min)
- Workflow logs show:
  - ✅ BTRFS mount success (~10 seconds)
  - ✅ Version tag generated (format: `40-20251011`)
  - ✅ Prev-ref generation outputs: "No valid prev-ref found - using fresh rechunking"
  - ✅ Rechunking completes in 5-7 minutes (fresh mode)
  - ✅ Image loaded and tagged
  - ✅ Pushed to GHCR
  - ✅ Cosign signing succeeds

**Success Criteria**:
- [ ] Build completes without errors
- [ ] Image published to `ghcr.io/dkolb/bazzite-dkub:latest`
- [ ] Image published with date tag: `ghcr.io/dkolb/bazzite-dkub:40-YYYYMMDD`
- [ ] Total duration within expected range (12-18 minutes)

---

### Test 1.2: Verify Published Image Metadata

**Objective**: Confirm rechunking metadata is present in published image

**Commands**:
```bash
# Check image exists
TAG="40-$(date +%Y%m%d)"
skopeo inspect docker://ghcr.io/dkolb/bazzite-dkub:$TAG

# Verify standard OCI labels
skopeo inspect docker://ghcr.io/dkolb/bazzite-dkub:$TAG | jq '.Labels | {
  title: .["org.opencontainers.image.title"],
  version: .["org.opencontainers.image.version"],
  url: .["org.opencontainers.image.url"],
  build_url: .["io.github-actions.build.url"]
}'

# Verify rechunking metadata
skopeo inspect docker://ghcr.io/dkolb/bazzite-dkub:$TAG | jq '.Labels | {
  rechunk_version: .["rechunk.version"],
  rechunk_chunks: .["rechunk.chunks"],
  rechunk_prev_ref: .["rechunk.prev-ref"]
}'
```

**Expected Results**:
- Standard OCI labels present and correct
- `rechunk.version` = "v1.2.4"
- `rechunk.chunks` = number (typically 7-10)
- `rechunk.prev-ref` = "" (empty for first build)

**Success Criteria**:
- [ ] All OCI labels present
- [ ] Rechunking metadata labels exist
- [ ] Chunk count in expected range (7-10)
- [ ] prev-ref is empty (first build)

---

### Test 1.3: Verify Cosign Signature

**Objective**: Confirm image is properly signed after rechunking

**Commands**:
```bash
TAG="40-$(date +%Y%m%d)"
cosign verify --key cosign.pub ghcr.io/dkolb/bazzite-dkub:$TAG
```

**Expected Results**:
- Signature verification succeeds
- Build information displayed

**Success Criteria**:
- [ ] Cosign verification passes
- [ ] Signature matches rechunked image (not pre-rechunk)

---

## Phase 2: Incremental Rechunking Testing

### Test 2.1: Make Trivial Change and Trigger Second Build

**Objective**: Verify incremental rechunking uses prev-ref correctly

**Steps**:
```bash
# Make trivial change
echo "<!-- Last updated: $(date) -->" >> README.md
git add README.md
git commit -m "test: trivial change to validate incremental rechunking"
git push origin 001-add-rechunking-to

# Wait for automatic build OR trigger manually via GitHub Actions UI
```

**Expected Results**:
- Build completes successfully
- Duration: 10-15 minutes (faster than first build)
- Workflow logs show:
  - ✅ Prev-ref generation outputs: "Using prev-ref: ghcr.io/dkolb/bazzite-dkub:40-YYYYMMDD"
  - ✅ Rechunking completes in 2-3 minutes (incremental mode - faster!)
  - ✅ Image published with new/same date tag

**Success Criteria**:
- [ ] Prev-ref is populated (not empty)
- [ ] Rechunking duration <3 minutes (incremental optimization)
- [ ] Build succeeds and image published

---

### Test 2.2: Verify Incremental Image Metadata

**Objective**: Confirm prev-ref is populated in second build's metadata

**Commands**:
```bash
TAG="40-$(date +%Y%m%d)"
skopeo inspect docker://ghcr.io/dkolb/bazzite-dkub:$TAG | jq '.Labels["rechunk.prev-ref"]'
```

**Expected Results**:
- prev-ref is NOT empty
- Format: `"ghcr.io/dkolb/bazzite-dkub:40-YYYYMMDD"` (previous build's date tag)

**Success Criteria**:
- [ ] prev-ref populated with valid image reference
- [ ] prev-ref tag is earlier date than current build (or same if same-day rebuild)

---

## Phase 3: VM Deployment and Update Size Testing

### Test 3.1: Deploy Rechunked Image to Test VM

**Objective**: Verify system boots with rechunked image

**Steps**:
```bash
# Option A: Fresh VM
just build-qcow2
just run-vm-qcow2

# Option B: Rebase existing system (recommended if you have existing VM)
# On VM:
sudo rpm-ostree rebase ghcr.io/dkolb/bazzite-dkub:latest
systemctl reboot
```

**After Reboot**:
```bash
# Verify deployment
rpm-ostree status
```

**Expected Results**:
- VM boots successfully
- `rpm-ostree status` shows rechunked image version
- System is functional

**Success Criteria**:
- [ ] VM boots without errors
- [ ] rpm-ostree shows correct image reference
- [ ] Applications work normally

---

### Test 3.2: Measure Update Download Size (THE BIG TEST!)

**Objective**: Validate 5-10x update size reduction (SC-001)

**Prerequisites**: 
- Test 2.1 completed (second build with trivial change)
- VM deployed from first rechunked build

**Steps on VM**:
```bash
# Check for updates
sudo rpm-ostree upgrade --check

# Preview update (shows download size)
sudo rpm-ostree upgrade --preview

# Apply update
sudo rpm-ostree upgrade

# Note the download size in output
```

**Expected Results** (CRITICAL SUCCESS CRITERION):
- **MINIMUM PASS**: Download size <400 MB (5x reduction from ~2GB baseline)
- **GOOD**: Download size 250-350 MB (6-8x reduction)
- **EXCELLENT**: Download size <250 MB (8x+ reduction)

**Success Criteria**:
- [ ] Update download size ≤400 MB (SC-001 minimum)
- [ ] Update download size shows 5-10x reduction vs. baseline
- [ ] Update applies successfully
- [ ] System remains functional after update

**Baseline Comparison**:
- Non-rechunked update: ~2000 MB (2 GB)
- Rechunked update (target): 200-400 MB

---

## Phase 4: Fresh Rechunking Mode Testing

### Test 4.1: Trigger Fresh Rechunking Build

**Objective**: Verify fresh-rechunk workflow dispatch input works

**Steps**:
1. Navigate to: https://github.com/dkolb/bazzite-dkub/actions/workflows/build.yml
2. Click "Run workflow"
3. Select branch: `001-add-rechunking-to` (or `main` if merged)
4. **Check the `fresh-rechunk` box** ✅
5. Click "Run workflow"

**Expected Results**:
- Workflow logs show: "Fresh rechunking mode enabled - skipping prev-ref"
- Prev-ref outputs are empty
- Rechunking takes 5-7 minutes (fresh mode duration)
- Image published successfully

**Success Criteria**:
- [ ] Fresh mode triggered correctly
- [ ] Prev-ref is empty (ignored)
- [ ] Rechunking duration matches fresh mode (5-7 min)
- [ ] Image quality is optimal (fresh chunk boundaries)

---

## Phase 5: Edge Case Testing

### Test 5.1: Same-Day Rebuild

**Objective**: Verify same-day rebuild doesn't use itself as prev-ref

**Steps**:
- Trigger two builds on the same day (within hours)
- Check second build's prev-ref generation logs

**Expected Results**:
- Second build detects: "Latest tag matches current build tag (same-day rebuild)"
- Falls back to fresh rechunking (empty prev-ref)

**Success Criteria**:
- [ ] No circular reference created
- [ ] Build succeeds with fresh rechunking

---

### Test 5.2: BTRFS Mount Failure Simulation (Optional)

**Objective**: Verify workflow fails gracefully if BTRFS unavailable

**Steps**:
- Not recommended for production testing
- Workflow should fail-fast with clear error message

**Expected**: Build fails with actionable error, no broken image published

---

## Phase 6: Performance Validation

### Test 6.1: Rechunking Overhead Check (SC-002)

**Objective**: Verify rechunking adds <8 minutes to build time

**Baseline** (from pre-rechunking builds):
- Typical build duration: ~10-12 minutes

**With Rechunking**:
- Fresh mode: +5-7 minutes → Total: 15-19 minutes ✅ (within <8 min overhead)
- Incremental mode: +2-3 minutes → Total: 12-15 minutes ✅ (well under threshold)

**Success Criteria**:
- [ ] Rechunking overhead <8 minutes (SC-002)
- [ ] Total workflow duration acceptable (<20 minutes)

---

### Test 6.2: Build Success Rate Monitoring (SC-003)

**Objective**: Track build reliability over 30 days

**Steps**:
- Monitor GitHub Actions builds for 30 days
- Track success/failure rate

**Target**: 100% success rate (SC-003)

**Success Criteria**:
- [ ] No rechunking-related build failures in 30-day window
- [ ] 100% publish success rate

---

## Phase 7: Documentation Validation

### Test 7.1: Verify Documentation Completeness (SC-009)

**Objective**: Confirm all documentation updated

**Checklist**:
- [ ] README.md includes rechunking feature
- [ ] README.md includes troubleshooting section
- [ ] AGENTS.md updated with rechunking details
- [ ] AGENTS.md includes maintainer troubleshooting
- [ ] Workflow comments explain rechunking steps
- [ ] All docs accurate and up-to-date

---

## Summary Checklist

### Must-Pass Tests (Blocking)
- [ ] Test 1.1: First build succeeds
- [ ] Test 1.2: Metadata present and correct
- [ ] Test 1.3: Cosign signature valid
- [ ] Test 2.1: Incremental build uses prev-ref
- [ ] Test 3.1: VM boots with rechunked image
- [ ] **Test 3.2: Update size ≤400 MB** ⭐ PRIMARY SUCCESS CRITERION

### Should-Pass Tests (Important)
- [ ] Test 2.2: prev-ref metadata populated
- [ ] Test 4.1: Fresh rechunking mode works
- [ ] Test 6.1: Overhead <8 minutes
- [ ] Test 7.1: Documentation complete

### Nice-to-Have Tests (Optional)
- [ ] Test 5.1: Same-day rebuild handling
- [ ] Test 6.2: 30-day success rate tracking

---

## Troubleshooting Guide

### Build Fails During BTRFS Mount
**Symptom**: "mkfs.btrfs: command not found" or mount errors  
**Solution**: GitHub Actions ubuntu-latest includes BTRFS by default. File issue if this occurs.

### Rechunking Times Out
**Symptom**: Step exceeds 10-minute timeout  
**Solution**: Check base image size. May need to increase timeout if base image >12GB.

### Update Size Not Reduced
**Symptom**: Update still ~2GB after rechunking  
**Possible Causes**:
1. First build (no prev-ref) - Expected, try second build
2. Major base image change - Normal, fresh rechunking applied
3. Rechunking failed silently - Check workflow logs for errors

### prev-ref Empty on Second Build
**Symptom**: Incremental build shows empty prev-ref  
**Causes**:
1. Same-day rebuild (same tag) - Expected behavior
2. GHCR query failed - Check skopeo/jq availability in logs
3. No matching tags found - Check GHCR for `40-YYYYMMDD` tags

---

## Test Results Log

**Date**: ___________  
**Tester**: ___________  
**Branch**: `001-add-rechunking-to`

| Test ID | Status | Notes |
|---------|--------|-------|
| 1.1 | ⬜ | |
| 1.2 | ⬜ | |
| 1.3 | ⬜ | |
| 2.1 | ⬜ | |
| 2.2 | ⬜ | |
| 3.1 | ⬜ | |
| **3.2** | ⬜ | **Update size: _____ MB** |
| 4.1 | ⬜ | |
| 6.1 | ⬜ | Overhead: _____ minutes |

**Overall Result**: ⬜ PASS / ⬜ FAIL  
**Ready for Merge**: ⬜ YES / ⬜ NO

---

## Post-Merge Monitoring

After merging to `main`:
1. Monitor first production build
2. Verify main branch builds continue successfully
3. Track update sizes reported by users
4. Schedule monthly fresh rechunking (1st of each month)
5. Monitor build success rate for 30 days (SC-003)

**Next Fresh Rechunking**: 2025-11-01 (monthly schedule)
