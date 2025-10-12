# Implementation Plan: Add Rechunking to Reduce Update Sizes

**Branch**: `001-add-rechunking-to` | **Date**: 2025-10-11 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-add-rechunking-to/spec.md`

## Summary

Integrate hhd-dev/rechunk GitHub Action v1.2.4 into the CI/CD build pipeline to reduce update download sizes by 5-10x (from ~2GB to 200-400MB) through OCI layer rechunking. Rechunking will be transparent to users, fully automated via GitHub Actions, with optional fresh rechunking mode for monthly maintenance and major version releases.

## Technical Context

**Base Image**: `ghcr.io/ublue-os/bazzite-dx:stable`  
**Package Manager**: N/A (no new packages installed - this is a GitHub Actions workflow modification only)  
**Container Runtime**: Podman/Buildah (used within GitHub Actions workflow)  
**Primary Build Tool**: GitHub Actions (`.github/workflows/build.yml` modification)  
**Image Registry**: `ghcr.io/dkolb/bazzite-dkub`    for this feature in the context of a bootc container image.

**Testing Method**: -->

- Local: `actionlint .github/workflows/build.yml` (workflow syntax validation)

- CI/CD: GitHub Actions execution with workflow logs**Base Image**: `ghcr.io/ublue-os/bazzite-dx:stable` (or specify if different)  

- VM: `just build-qcow2 && just run-vm-qcow2` followed by `rpm-ostree upgrade` to measure update sizes  **Package Manager**: `dnf5` (required for all package installations)  

**Container Runtime**: Podman/Buildah  

**Deployment Target**: bootc-based systems using rpm-ostree (bazzite-dkub installations)  **Primary Build Tool**: `just` (command runner)  

**Filesystem Constraints**: N/A (no filesystem modifications - workflow-only feature)  **Image Registry**: `ghcr.io/dkolb/bazzite-dkub`  

**Build Phase**: GitHub Actions workflow steps (insert rechunking between build and GHCR push)  **Testing Method**: [e.g., `just build`, `just build-qcow2 && just run-vm-qcow2`, or NEEDS CLARIFICATION]  

**Performance Goals**: **Deployment Target**: [e.g., bootc-based system, VM, ISO installation, or NEEDS CLARIFICATION]  

- Rechunking overhead <8 minutes (SC-002)**Filesystem Constraints**: [e.g., modifies `/etc` only, uses optfix for `/opt`, `/var` clean, or NEEDS CLARIFICATION]  

- Update download size reduction: 5-10x for minor changes (SC-001)**Build Phase**: [e.g., `build.sh` package installation, static file copy, systemd service enable, or NEEDS CLARIFICATION]  

- 100% build success rate over 30 days (SC-003)  **Performance Goals**: [domain-specific, e.g., image size <2GB, build time <10min, or NEEDS CLARIFICATION]  

**Integration Requirements**: [e.g., must work with existing GearLever setup, 1Password integration, or N/A]

**Integration Requirements**: 

- Must integrate with existing Cosign signing workflow (signing happens AFTER rechunking)## Constitution Check

- Must preserve OCI labels from metadata step

- Must work with GitHub Actions ubuntu-latest runners (BTRFS support required)*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- No changes to package installations, static files, or systemd services

**Refer to `.specify/memory/constitution.md` for complete principles.**

## Constitution Check

- [ ] **I. Immutability & Base Layer Integrity**: Does this feature modify `/usr` at runtime? Does it use optfix pattern for `/opt` installations? Are user files in `/etc/skel/`?

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*- [ ] **II. Documentation-First Development**: Is the feature documented in both `README.md` and `AGENTS.md`? Are inline comments in `build.sh` clear?

- [ ] **III. Container-Native Workflows**: Does this use `dnf5` for packages? Is signing/publishing to GHCR configured? Are `just` recipes provided?

**Refer to `.specify/memory/constitution.md` for complete principles.**- [ ] **IV. Automated Testing & CI/CD**: Can this be tested with `just build`? Does it pass `bootc container lint`? Is CI/CD updated if needed?

- [ ] **V. Universal Blue Compatibility**: Does this maintain base image compatibility? Does it follow Universal Blue conventions?

- [x] **I. Immutability & Base Layer Integrity**: ✅ No runtime modifications. No `/usr`, `/opt`, or `/var` changes. This is purely a build pipeline optimization affecting OCI image layer structure, not filesystem content.

- [x] **II. Documentation-First Development**: ✅ Spec includes documentation requirements (FR-010, SC-009). README.md and AGENTS.md updates are part of success criteria. Workflow comments will explain rechunking steps.**Violations Requiring Justification**: [List any principle violations with detailed rationale, or state "None"]

- [x] **III. Container-Native Workflows**: ✅ Uses container-native rechunking via hhd-dev/rechunk GitHub Action. Images published to GHCR with Cosign signing. BTRFS storage mount follows container storage patterns.

- [x] **IV. Automated Testing & CI/CD**: ✅ Rechunking fully automated in GitHub Actions. Workflow syntax validated with actionlint. Build failures block publishing (FR-006). VM testing validates end-to-end update experience.## Project Structure

- [x] **V. Universal Blue Compatibility**: ✅ Rechunking follows Universal Blue community practices (research references ublue-os/bazzite build.yml). Maintains OSTree/rpm-ostree compatibility. OCI standard labels preserved.

### Documentation (this feature)

**Violations Requiring Justification**: None - all 5 principles satisfied.

```

## Project Structure

### Documentation (this feature)

```
specs/001-add-rechunking-to/
├── spec.md          ✅ Complete (clarified 2025-10-11)
├── plan.md          ✅ Complete (this file, regenerated with clarifications)
├── research.md      ✅ Complete (10 decisions with clarifications)
├── data-model.md    ✅ Complete (6 entities with GHCR query algorithm)
├── contracts/       ✅ Complete (workflow contract)
├── quickstart.md    ✅ Complete (7-step implementation guide)
└── tasks.md         ✅ Complete (29 tasks organized by user story)
```

### Source Code (repository root)

```
# Bootc Container Structure (Standard for this project)
Containerfile                    # Main image definition
build_files/
├── build.sh                     # Package installations, service enablement
└── files/                       # Static files copied to root filesystem
    ├── etc/                     # System configuration
    │   ├── skel/                # User home directory templates
    │   └── yum.repos.d/         # Package repository definitions
    └── usr/
        ├── lib/
        │   ├── opt/             # Optfix pattern: immutable /opt installations
        │   ├── systemd/system/  # Systemd service units
        │   └── tmpfiles.d/      # Temporary file configurations
        ├── libexec/             # Helper scripts
        └── share/ublue-os/just/ # Custom ujust recipes (optional)
```

### Code Files (to be modified/created)

```
.github/workflows/
  build.yml        🎯 PRIMARY TARGET: Insert rechunking steps

build_files/
  build.sh         ⚫ NO CHANGES (no new packages)
  files/           ⚫ NO CHANGES (no static files)

README.md          📝 Documentation update (rechunking feature description)
AGENTS.md          📝 Documentation update (maintainer reference)
```

**Note**: This feature modifies ONLY `.github/workflows/build.yml` plus documentation. No package installations, no static files, no systemd services. Pure CI/CD pipeline enhancement.

## Design Artifacts Review

### Required Documents
- [x] **spec.md**: ✅ Complete with 4 prioritized user stories, 10 functional requirements, 10 success criteria, clarified via 5-question session (concurrent builds, fresh rechunk schedule, tag retention, chunk count, Cosign verification)        ├── libexec/             # Helper scripts

- [ ] **research.md**: ⏳ To be regenerated (10 technical decisions with clarification updates)        └── share/ublue-os/just/ # Custom ujust recipes (optional)

- [ ] **data-model.md**: ⏳ To be regenerated (6 entities: OCI images, prev-ref, labels, workflow context, BTRFS mount)

- [ ] **contracts/**: ⏳ To be regenerated (workflow contract with 7 steps, prev-ref generation)# Feature-Specific Modifications

- [ ] **quickstart.md**: ⏳ To be regenerated (7-step implementation guide)[Document which files/directories this feature adds or modifies]

# Example:

### Complexity Tracking# - build_files/build.sh: Add `dnf5 install -y new-package`

# - build_files/files/etc/skel/.config/app/: Add app configuration

**Violations of Constitution Principles**: 0 (zero violations - all 5 principles satisfied)# - build_files/files/usr/lib/systemd/system/: Add new-service.service

```

**Current Complexity Score**: 0  

- No new packages to install**Structure Decision**: [Describe what this feature changes in the bootc container structure and why]

- No static files to manage

- No systemd services to configure## Complexity Tracking

- No `/opt` installations requiring optfix pattern

- No user-specific files requiring `/etc/skel/` placement*Fill ONLY if Constitution Check has violations that must be justified*



**Complexity Budget**: N/A (workflow-only modification has minimal complexity)| Violation | Why Needed | Simpler Alternative Rejected Because |

|-----------|------------|-------------------------------------|

## Phase Checklist| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |

| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |

### Phase 0: Outline & Research ⏳

**Goal**: Resolve all technical unknowns and establish implementation approach.

**Status**: READY TO REGENERATE with clarifications

**Research Questions Resolved**:
1. ✅ Which rechunking tool? → hhd-dev/rechunk v1.2.4 (SHA: 5fbe1d3a639615d2548d83bc888360de6267b1a2)
2. ✅ How to generate prev-ref? → GHCR query with `skopeo list-tags` + jq filtering for `^40-[0-9]{8}$`
3. ✅ Tag format? → 40-YYYYMMDD (8 digits)
4. ✅ Fresh rechunking triggers? → Monthly maintenance (1st of month)
5. ✅ Tag retention? → Keep all tags indefinitely
6. ✅ Chunk count target? → 7-10 chunks (informational only)
7. ✅ Concurrent builds? → Accept race condition, document limitation
8. ✅ Cosign verification? → Document in troubleshooting, trust existing integration
9. ✅ BTRFS requirements? → 50GB minimum, mount at `/var/tmp/rechunk-btrfs`
10. ✅ Universal Blue patterns? → Follow ublue-os/bazzite build.yml (lines 315-349)

**Next**: Generate `research.md` with 10 technical decisions documenting rationale and alternatives.

---

### Phase 1: Design & Contracts ⏳

**Goal**: Define data model, API contracts, and implementation roadmap.

**Status**: PENDING (after research.md regeneration)

#### Subtask 1.1: Data Model

**File**: `data-model.md`

**Entities** (from spec + clarifications):
1. OCI Image (Pre-Rechunking)
2. OCI Image (Post-Rechunking)
3. Previous Reference (prev-ref with GHCR query algorithm)
4. OCI Image Labels
5. Workflow Execution Context
6. BTRFS Storage Mount

#### Subtask 1.2: Workflow Contracts

**File**: `contracts/workflow-contract.md`

**Workflow Steps**:
1. Build Image
2. Mount BTRFS Storage
3. Generate Version Tag
4. Generate Previous Reference (GHCR query)
5. Run Rechunker
6. Load Rechunked Image
7. Push to GHCR
8. Sign with Cosign

#### Subtask 1.3: Quickstart Guide

**File**: `quickstart.md`

**Implementation Roadmap**: 7 steps from workflow modification to production deployment

#### Subtask 1.4: Update Agent Context

**Script**: `.specify/scripts/bash/update-agent-context.sh copilot`

**Technologies**: hhd-dev/rechunk, skopeo, jq, BTRFS

---

### Phase 2: Task Breakdown

**Goal**: Break down implementation into executable tasks.

**Status**: PENDING (run after Phase 0 + Phase 1 complete)

**Command**: Follow `.github/prompts/speckit.tasks.prompt.md`

---

## Implementation Readiness

### Prerequisites Met
- [x] Feature specification complete and clarified (5 Q&A session)
- [x] Constitution check passed (all 5 principles satisfied)
- [x] All technical unknowns resolved

### Ready for Phase 0 Execution
✅ All research questions answered - ready to generate research.md

### Next Steps
1. Generate `research.md` with 10 technical decisions
2. Generate `data-model.md` with 6 entities
3. Generate `contracts/workflow-contract.md` with workflow steps
4. Generate `quickstart.md` with implementation guide
5. Update agent context via script
6. Generate `tasks.md` with task breakdown

---

## Notes

### Clarifications Applied (2025-10-11)
- Concurrent builds: Accept race condition (rare in single-maintainer project)
- Fresh rechunking: Monthly maintenance schedule (1st of month)
- Tag retention: Keep all tags indefinitely
- Chunk count: 7-10 typical (informational only)
- Cosign verification: Document in troubleshooting

### Key Technical Decisions
- Tag format: `40-YYYYMMDD` (8 digits)
- Prev-ref: GHCR query via skopeo + jq
- BTRFS: 50GB minimum storage
- Rechunking overhead: <8 minutes target
- Update reduction: 5-10x (80-95% bandwidth savings)

### Workflow-Only Feature
✅ No packages, no static files, no systemd services  
✅ Only `.github/workflows/build.yml` + documentation  
✅ Minimal constitution compliance surface area
