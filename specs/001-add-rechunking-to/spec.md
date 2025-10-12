# Feature Specification: Add Rechunking to Reduce Update Sizes

**Feature Branch**: `001-add-rechunking-to`  
**Created**: 2025-01-18  
**Status**: Draft  
**Input**: User description: "Add rechunking to help ease the size. Looking for 5-10x download reduction for updates. Use the hhd-dev/rechunk GitHub Action to rechunk the images, follow how other custom images have integrated the rechunk action into their workflows, and use #get_file_contents to retrieve the file."

## User Scenarios & Testing *(mandatory)*

<!--
  IMPORTANT: User stories should be PRIORITIZED as user journeys ordered by importance.
  Each user story/journey must be INDEPENDENTLY TESTABLE - meaning if you implement just ONE of them,
  you should still have a viable MVP (Minimum Viable Product) that delivers value.
  
  Assign priorities (P1, P2, P3, etc.) to each story, where P1 is the most critical.
  Think of each story as a standalone slice of functionality that can be:
  - Developed independently
  - Tested independently
  - Deployed independently
  - Demonstrated to users independently
-->

### User Story 1 - Faster System Updates (Priority: P1)

As a bazzite-dkub user running `rpm-ostree upgrade`, I want dramatically reduced download sizes (5-10x smaller) so that I can update my system faster and consume less bandwidth, especially on metered connections.

**Why this priority**: This delivers the core value proposition immediately—smaller updates benefit all users on every update cycle. It's the primary reason rechunking exists and can be independently validated by comparing update sizes before/after implementation.

**Independent Test**: Can be fully tested by building a rechunked image, deploying it to a test system, making a small change (e.g., updating README.md), building again, then measuring the download size of the update via `rpm-ostree upgrade --check-diff`. Delivers immediate value even without subsequent user stories.

**Acceptance Scenarios**:

1. **Given** user is on bazzite-dkub v1.0 (non-rechunked), **When** a new version v1.1 is released with only documentation changes, **Then** update download is reduced by 5-10x compared to baseline (from ~2GB to 200-400MB)
2. **Given** user is on bazzite-dkub v1.5 (rechunked), **When** a new version v1.6 is released with package updates, **Then** only changed chunks are downloaded, resulting in 80-95% bandwidth reduction
3. **Given** user has metered connection, **When** they check for updates with `rpm-ostree upgrade --check`, **Then** they can see the reduced download size before committing to the update

---

### User Story 2 - Transparent CI/CD Integration (Priority: P1)

As the maintainer, I want rechunking to be automatically integrated into the GitHub Actions build pipeline so that every published image is optimally chunked without manual intervention or workflow changes beyond initial setup.

**Why this priority**: Without automated integration, rechunking won't happen consistently. This ensures rechunking is applied to every build, making it sustainable. It's independently testable by observing GitHub Actions logs and can be validated without user-facing testing.

**Independent Test**: Merge the workflow changes and trigger a build via push or manual dispatch. Check GitHub Actions logs for successful rechunking step execution with expected inputs (prev-ref, version, labels). Verify the published image in GHCR has OCI annotations indicating rechunking was applied.

**Acceptance Scenarios**:

1. **Given** a code change is pushed to `main`, **When** GitHub Actions builds the image, **Then** the rechunking step executes after the build completes and before pushing to GHCR
2. **Given** a manual workflow dispatch is triggered, **When** the build runs, **Then** rechunking uses the correct `prev-ref` (previous version tag) to optimize against the last published image
3. **Given** the rechunking step fails, **When** reviewing the workflow run, **Then** the entire build fails with clear error messages (no silent failures or partially rechunked images)
4. **Given** a successful rechunked build, **When** inspecting the image in GHCR, **Then** OCI labels show rechunking metadata (version, prev-ref, chunk statistics)

---

### User Story 3 - Transparent User Experience (Priority: P2)

As a bazzite-dkub user, I want rechunking to be completely transparent during updates so that my existing update workflow (`rpm-ostree upgrade`, `systemctl reboot`) remains unchanged with no new commands, configurations, or error messages.

**Why this priority**: User experience must not degrade. While rechunking benefits users with smaller downloads, it should require zero learning curve. This is secondary to P1 stories because rechunking is inherently transparent—this story validates that transparency.

**Independent Test**: After deploying a rechunked image to a test VM, perform a standard update workflow using only documented rpm-ostree commands. Success means no user-visible changes except faster downloads.

**Acceptance Scenarios**:

1. **Given** user runs `rpm-ostree upgrade`, **When** the update downloads and deploys, **Then** the command completes successfully with no rechunking-specific warnings or prompts
2. **Given** user runs `rpm-ostree status`, **When** viewing the deployment list, **Then** both rechunked and non-rechunked deployments appear identically (no visual distinction)
3. **Given** user reboots into a rechunked deployment, **When** system boots, **Then** all applications, services, and configurations work identically to non-rechunked deployments
4. **Given** user encounters an issue and needs to rollback, **When** they run `rpm-ostree rollback`, **Then** rollback between rechunked and non-rechunked versions works seamlessly

---

### User Story 4 - Fresh Rechunking on Major Updates (Priority: P3)

As the maintainer, I want the ability to trigger fresh rechunking (without prev-ref) when publishing major versions or performing monthly maintenance so that chunk optimization isn't constrained by outdated historical references.

**Why this priority**: Over time, incremental rechunking may accumulate suboptimal chunking decisions. Fresh rechunking periodically resets optimization. This is lower priority because incremental rechunking handles 95% of cases—fresh rechunking is an optimization of an optimization. Monthly maintenance provides predictable optimization cycles.

**Independent Test**: Manually trigger a workflow with fresh-rechunk parameter set to true. Verify that rechunking step omits `prev-ref` input and the resulting image has optimal chunking independent of previous versions.

**Acceptance Scenarios**:

1. **Given** maintainer wants to release v2.0 (major version), **When** triggering GitHub Actions workflow with `fresh-rechunk: true`, **Then** rechunking executes without `prev-ref`, creating optimal chunks from scratch
2. **Given** monthly maintenance schedule (1st of month), **When** maintainer triggers workflow with `fresh-rechunk: true`, **Then** chunks are optimized fresh regardless of incremental build history
3. **Given** fresh rechunking is enabled, **When** build completes, **Then** OCI labels indicate fresh rechunking mode and do not reference a prev-ref

---

### Edge Cases

- **What happens when `prev-ref` points to a non-existent or deleted image tag?** - Rechunking should gracefully fall back to fresh rechunking mode or fail the build with a clear error message indicating the missing reference.
- **How does the system handle rechunking timeout?** - If rechunking exceeds reasonable time limits (~10 minutes), the workflow should fail with timeout error rather than hanging indefinitely.
- **What happens if BTRFS storage is full during rechunking?** - Rechunking should fail gracefully with clear disk space error, preventing corrupt image publication.
- **How does rechunking interact with Cosign signing?** - Signing must occur AFTER rechunking on the final rechunked image, not the raw build. OCI labels from rechunking must be preserved through signing.
- **What if the GitHub Actions runner lacks BTRFS support?** - Workflow should fail early with actionable error message indicating BTRFS requirement (this is a known rechunk action requirement per hhd-dev/rechunk documentation).
- **How are multi-architecture images handled?** - If future bazzite-dkub builds support multi-arch (amd64, arm64), rechunking must be applied per architecture with arch-specific prev-refs.
- **What if concurrent builds run simultaneously?** - Accepted as known limitation (extremely rare for single-maintainer project with daily schedule). Worst case: one build might use slightly stale prev-ref, resulting in suboptimal but valid chunking. Both builds will complete successfully.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Build pipeline MUST integrate hhd-dev/rechunk GitHub Action v1.2.4 or later into `.github/workflows/build.yml` after image build and before GHCR push
- **FR-002**: Rechunking MUST use `prev-ref` parameter pointing to the previous published version tag to enable incremental optimization (e.g., `ghcr.io/dkolb/bazzite-dkub:40-20250117` for baseline comparison)
- **FR-003**: Rechunking MUST tag the output image with semantic version tag generated from `generate-version` step (format: `40-YYYYMMDD` where Fedora 40 prefix is followed by 8-digit date: YYYYMMDD = 4-digit year + 2-digit month + 2-digit day)
- **FR-004**: Rechunking MUST apply OCI labels including: `org.opencontainers.image.title`, `org.opencontainers.image.description`, `org.opencontainers.image.version`, `org.opencontainers.image.url`, and `io.github-actions.build.url` for metadata consistency
- **FR-005**: Build workflow MUST mount BTRFS storage with appropriate size (minimum 50GB recommended per hhd-dev/rechunk best practices) for rechunking intermediate files
- **FR-006**: Rechunking step MUST fail the entire build if it encounters errors (no silent failures or partial rechunking)
- **FR-007**: Published images MUST maintain backward compatibility with rpm-ostree clients (rechunked images must be indistinguishable from non-rechunked images to end users)
- **FR-008**: Build workflow MUST support optional fresh rechunking mode via workflow input parameter (e.g., `fresh-rechunk: true`) that omits `prev-ref` for clean rechunking
- **FR-009**: Rechunking configuration MUST align with Universal Blue community practices (reference: ublue-os/bazzite build.yml lines 315-349 from research)
- **FR-010**: Documentation MUST be updated in README.md and AGENTS.md to reflect rechunking integration, expected update size reductions, and troubleshooting guidance (included in feature PR before merge)

### Key Entities *(include if feature involves data)*

- **Rechunked Image**: OCI container image output from hhd-dev/rechunk action, stored in GHCR with tag format `ghcr.io/dkolb/bazzite-dkub:40-YYYYMMDD` (8 digits). Contains optimized layers (chunks) designed for minimal delta downloads. Includes OCI annotations with rechunking metadata (version, prev-ref, chunk statistics).
  
- **Previous Reference (prev-ref)**: Git tag or image reference (e.g., `ghcr.io/dkolb/bazzite-dkub:40-20250117`) used as baseline for incremental rechunking. Determined by querying GHCR for the latest published tag matching pattern `^40-[0-9]{8}$`. Determines which chunks are reused vs. created fresh.

- **Build Metadata**: OCI labels applied during rechunking step, including `org.opencontainers.image.*` standard labels and custom labels like `io.github-actions.build.url`. Ensures image traceability and compatibility with Universal Blue tooling.

- **BTRFS Storage Mount**: Temporary filesystem mounted during GitHub Actions workflow execution to provide BTRFS-backed storage required by rechunk action for efficient copy-on-write operations during chunk creation.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Update download sizes MUST be reduced by 5-10x for minor changes (e.g., documentation-only updates measured via `rpm-ostree upgrade --check` showing <400MB download vs. baseline ~2GB)
- **SC-002**: Rechunking step overhead MUST complete within 8 minutes on GitHub Actions runners (measured from workflow logs from rechunk step start to completion)
- **SC-003**: 100% of builds MUST successfully complete rechunking without failures over a 30-day observation period (zero silent failures or corrupted images)
- **SC-004**: Rechunked images MUST pass smoke tests on VM deployment (boot successfully, applications launch, rpm-ostree operations work) with zero regressions compared to non-rechunked baseline
- **SC-005**: Published images MUST include all required OCI labels verifiable via `skopeo inspect docker://ghcr.io/dkolb/bazzite-dkub:latest` showing rechunking metadata
- **SC-006**: Update bandwidth consumption MUST decrease by 80-90% for typical package updates (measured across multiple update cycles in test environment, aligning with 5-10x reduction target)
- **SC-007**: Rollback operations between rechunked and non-rechunked versions MUST succeed with zero data loss or configuration drift
- **SC-008**: Fresh rechunking mode MUST produce images with <5% larger initial download size compared to incremental rechunked image size (e.g., if incremental = 300MB, fresh should be <315MB; acceptable trade-off for long-term optimization)
- **SC-009**: Documentation MUST be updated with rechunking feature description, troubleshooting section, and links to Universal Blue rechunking resources before merge (included in feature PR)
- **SC-010**: GitHub Actions workflow logs MUST include rechunking statistics (chunk count, size reduction percentage, prev-ref used) for build observability

**Note**: Target chunk count for optimal rechunking is 7-10 chunks (typical for bootc/OSTree images per Universal Blue community patterns). This is informational only—hhd-dev/rechunk determines chunk count automatically based on layer analysis.

## Clarifications

### Session 2025-10-11

- Q: How should prev-ref generation handle concurrent builds (e.g., scheduled build + manual dispatch running simultaneously)? → A: Accept race condition - Document as known limitation; extremely rare in practice for single-maintainer project with daily schedule
- Q: What defines "significant" for base image changes when triggering fresh rechunking? → A: Monthly maintenance - Schedule fresh rechunk as periodic maintenance (1st of every month) regardless of base changes
- Q: How long should previous image tags be retained in GHCR before cleanup? → A: Keep all tags indefinitely - Never delete tags (storage cost negligible, will address if space becomes issue)
- Q: What is the target chunk count for optimal rechunking (used to assess rechunking quality)? → A: 7-10 chunks (informational only, not a hard requirement; hhd-dev/rechunk determines automatically)
- Q: Should we add explicit verification of Cosign signatures to acceptance criteria, or trust existing integration? → A: Document as operational note - Trust existing Cosign integration, add troubleshooting note to documentation but don't add to acceptance tests
- Q: What constitutes a "silent failure" in SC-003? → A: Silent failure = build completes with exit code 0 but produces corrupted/incomplete image. Normal failures (non-zero exit codes) are acceptable and trackable via GitHub Actions logs.

## Assumptions

- GitHub Actions runners will have sufficient resources (CPU, memory, disk) to support BTRFS mount and rechunking operations (verified in Universal Blue community builds)
- Base image `ghcr.io/ublue-os/bazzite-dx:stable` will remain compatible with rechunking process (no breaking changes to OSTree structure)
- hhd-dev/rechunk GitHub Action will maintain stability and backward compatibility for v1.2.4+ (pinned SHA: `5fbe1d3a639615d2548d83bc888360de6267b1a2`)
- GHCR (GitHub Container Registry) will continue supporting OCI image storage with annotations and labels required by rechunking
- rpm-ostree client version used by bazzite-dkub users will support chunked image downloads (standard OCI protocol support)
- Network bandwidth reduction claims (5-10x) are based on Universal Blue community data and will apply similarly to bazzite-dkub update patterns
- First rechunked build will have no `prev-ref` (fresh rechunking mode) since no previous rechunked baseline exists
- Cosign signing workflow will continue to work with rechunked images without modification (signing occurs post-rechunking)

## Dependencies

- **External**: `hhd-dev/rechunk` GitHub Action v1.2.4 or later (pinned SHA recommended for reproducibility)
- **External**: BTRFS support in GitHub Actions runner (provided by ubuntu-latest runner images)
- **External**: GitHub Container Registry (GHCR) with write permissions for pushing rechunked images
- **Internal**: `.github/workflows/build.yml` workflow with existing build, version generation, and signing steps
- **Internal**: Existing version tagging scheme (e.g., `40-YYYYMMDD`) used for prev-ref generation
- **Internal**: OCI label structure defined in current workflow (must be preserved/extended for rechunking metadata)
- **Internal**: Cosign signing setup with secrets configured (`cosign.key` in GitHub Secrets)
- **Documentation**: Universal Blue rechunking documentation and community examples (reference for troubleshooting)
- **Knowledge**: Bazzite build.yml (lines 315-349) as reference implementation pattern

## Constraints

- **Technical**: Rechunking requires BTRFS filesystem—cannot use ext4, xfs, or other filesystems for intermediate storage
- **Technical**: GitHub Actions free tier has 6-hour workflow timeout—rechunking must complete well within this limit (target: <8 minutes overhead)
- **Technical**: Rechunked images are OCI-compliant but OSTree-specific—not suitable for non-OSTree container workloads (bootc/rpm-ostree only)
- **Process**: Initial rechunked build cannot use incremental optimization (no prev-ref exists)—first build will be fresh rechunking
- **Process**: Breaking changes in hhd-dev/rechunk action require workflow updates—recommend pinning to specific SHA for stability
- **Resource**: BTRFS mount consumes disk space on GitHub Actions runner—minimum 50GB recommended, may require cleanup between builds
- **Compatibility**: Rechunking must maintain OCI image format compatibility with existing Cosign signing workflow (no format breaking changes)
- **Testing**: Full validation requires deploying to physical/virtual hardware with rpm-ostree—cannot fully test in containerized environments
- **Documentation**: Constitution Principle 2 (Documentation-First Development) requires README.md and AGENTS.md updates before merge

## Out of Scope

- **Custom rechunking algorithms**: Using custom chunking logic instead of hhd-dev/rechunk action defaults
- **Alternative rechunking tools**: Evaluating or integrating non-hhd-dev/rechunk solutions (e.g., custom ostree chunking tools)
- **Multi-architecture rechunking**: Rechunking arm64 or other architectures (current project is amd64-only; future enhancement)
- **Rechunking analytics dashboard**: Building UI/dashboard to visualize chunk statistics across builds (observability via workflow logs sufficient for MVP)
- **Automatic tag cleanup**: Implementing automated deletion of old image tags from GHCR (tags kept indefinitely, manual cleanup if needed)
- **Automated fresh rechunking schedule**: Automatically triggering fresh rechunking on schedule (maintainer triggers manually on 1st of month)
- **Client-side rechunking**: Implementing chunking optimizations in rpm-ostree client (outside project control)
- **Rechunking of ISO/VM images**: Applying rechunking to `build-iso` or `build-qcow2` outputs (focus on container images only)
- **Performance benchmarking suite**: Automated testing of update download speeds across various scenarios (manual validation sufficient)
- **Rechunking policy configuration**: Allowing users to configure chunk size, compression, or other rechunking parameters (use action defaults)
- **Historical rechunking migration**: Retroactively rechunking previous image versions already published to GHCR (apply to new builds only)
