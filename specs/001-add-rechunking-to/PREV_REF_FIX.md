# Prev-Ref Fix for Same-Day Rebuilds

**Date**: October 12, 2025  
**Issue**: Large downloads (2GB) on same-day rebuilds despite rechunking  
**Root Cause**: Prev-ref logic rejected same-day images by tag comparison  

## Problem Analysis

### Original Logic (Flawed)
```bash
# Validate tag exists and is not current build's tag (prevent circular reference)
CURRENT_TAG="${{ steps.generate-version.outputs.tag }}"
if [[ -n "$LATEST_TAG" ]] && [[ "$LATEST_TAG" != "$CURRENT_TAG" ]]; then
  # Use prev-ref
else
  # Skip prev-ref (same-day rebuild)
fi
```

### Why This Failed

1. **Date-based tags**: All builds on same day get tag `40-20251012`
2. **Multiple builds per day**: Scheduled (10:05 UTC) + manual pushes
3. **Tag collision**: Build #2 finds tag `40-20251012` from Build #1
4. **Rejection**: Logic rejects because `LATEST_TAG == CURRENT_TAG`
5. **Result**: Every same-day build does **fresh rechunking** (no optimization)

### Evidence from Logs

- **First build** (02:46 UTC): "No previous rechunked images found (first build)" ✓
- **Second build** (10:21 UTC): "Latest tag matches current build tag (same-day rebuild)" ✗
- **Third build** (20:53 UTC): "Latest tag matches current build tag (same-day rebuild)" ✗

Builds #2 and #3 should have used Build #1 and #2 as prev-ref respectively.

## Solution: Manifest Age Check

### New Logic
```bash
# Get workflow start time
WORKFLOW_START=$(date -u +%s)

# Query for latest tag
LATEST_TAG=$(skopeo list-tags ...)

# Check manifest creation time
MANIFEST_CREATED=$(skopeo inspect docker://ghcr.io/dkolb/bazzite-dkub:$LATEST_TAG | jq -r '.Created')
MANIFEST_EPOCH=$(date -d "$MANIFEST_CREATED" -u +%s)
TIME_DIFF=$((WORKFLOW_START - MANIFEST_EPOCH))

# Use prev-ref if manifest is at least 60 seconds old
if [[ $TIME_DIFF -gt 60 ]]; then
  # Use as prev-ref (it's from a previous build)
else
  # Skip (it's from this workflow run)
fi
```

### Benefits

1. **Same-day rebuilds work**: Build #2 can use Build #1 (same tag, different digest)
2. **Prevents circular refs**: 60-second threshold prevents using current build
3. **Digest-aware**: Uses actual manifest creation time, not tag collision
4. **Robust**: Works across days, months, and same-day scenarios

## Expected Behavior

### Scenario 1: First Build of the Day
- **Latest tag**: `40-20251011` (yesterday)
- **Current tag**: `40-20251012` (today)
- **Result**: Uses `40-20251011` as prev-ref ✓
- **Download**: ~500MB (incremental)

### Scenario 2: Same-Day Rebuild
- **Latest tag**: `40-20251012` (same day, earlier build)
- **Manifest age**: 7 hours (25,200 seconds)
- **Current tag**: `40-20251012` (same day)
- **Result**: Uses `40-20251012` as prev-ref ✓ (NEW BEHAVIOR)
- **Download**: ~500MB (incremental from earlier build)

### Scenario 3: Rapid Rebuilds (< 60s)
- **Latest tag**: `40-20251012` (same day)
- **Manifest age**: 30 seconds
- **Result**: Skips prev-ref (safety check) ✓
- **Download**: 2GB (fresh rechunk)

## Testing Plan

1. **Verify first build tomorrow**: Should use `40-20251012` as prev-ref
2. **Verify second build tomorrow**: Should use first build's manifest (same tag)
3. **Monitor download sizes**: Should be ~500MB for incremental builds
4. **Check logs**: Should show "Using prev-ref: ..." with manifest age

## Rollout

- **Status**: Fix applied to `build.yml`
- **Next build**: Will test new logic
- **Monitoring**: Check workflow logs for prev-ref usage
- **Rollback**: If issues, revert to fresh-rechunk mode via workflow dispatch

## Documentation Updates

- Updated `AGENTS.md` with manifest age logic
- Added troubleshooting section for prev-ref debugging
- Documented expected download sizes (fresh: 2GB, incremental: 500MB)
