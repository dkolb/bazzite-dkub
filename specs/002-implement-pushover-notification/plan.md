# Implementation Plan: Pushover notification when daily build produces a new image

**Branch**: `002-implement-pushover-notification` | **Date**: 2025-10-18 | **Spec**: `./spec.md`
**Input**: Feature specification from `/specs/002-implement-pushover-notification/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Primary requirement: send a concise Pushover push notification to the maintainer's devices when the daily `build.yml` workflow publishes a new container image to GHCR (i.e., the pushed image digest differs from the previously published digest for the canonical tag).

Technical approach: add three workflow steps to the existing `build.yml`: (1) fetch the registry digest for the canonical tag before pushing (pre-push snapshot), (2) run the existing `redhat-actions/push-to-registry` push (already present in the workflow) which exposes the pushed digest via `steps.push.outputs.digest`, and (3) compare pre-push digest vs pushed digest and, if different, trigger `umahmood/pushover-actions` to deliver a minimal payload (tag, digest, link). Credentials (`PUSHOVER_TOKEN` and `PUSHOVER_USER`) will be stored in repository secrets.

## Technical Context

<!--
  ACTION REQUIRED: Replace the content in this section with the technical details
  for this feature in the context of a bootc container image.
-->

**Base Image**: `ghcr.io/ublue-os/bazzite-dx:stable`  
**Package Manager**: `dnf5`  
**Container Runtime**: Podman/Buildah  
**Primary Build Tool**: `just`  
**Image Registry**: `ghcr.io/dkolb/bazzite-dkub`  
**Testing Method**: `just build` for image changes; GitHub Actions runs for workflow verification  
**Deployment Target**: GHCR (GitHub Container Registry)  
**Filesystem Constraints**: No image filesystem changes — workflow-only feature  
**Build Phase**: CI workflow modification only — add steps to `.github/workflows/build.yml`  
**Performance Goals**: Notification logic must add <30s overhead to the workflow runtime; deliver notifications within 5 minutes for 95% of events  
**Integration Requirements**: GHCR manifest API for digest fetch; `umahmood/pushover-actions` for notifications; repository secrets `PUSHOVER_TOKEN` and `PUSHOVER_USER`

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Refer to `.specify/memory/constitution.md` for complete principles.**

- [ ] **I. Immutability & Base Layer Integrity**: Does this feature modify `/usr` at runtime? Does it use optfix pattern for `/opt` installations? Are user files in `/etc/skel/`?
- [ ] **II. Documentation-First Development**: Is the feature documented in both `README.md` and `AGENTS.md`? Are inline comments in `build.sh` clear?
- [ ] **III. Container-Native Workflows**: Does this use `dnf5` for packages? Is signing/publishing to GHCR configured? Are `just` recipes provided?
- [ ] **IV. Automated Testing & CI/CD**: Can this be tested with `just build`? Does it pass `bootc container lint`? Is CI/CD updated if needed?
- [ ] **V. Universal Blue Compatibility**: Does this maintain base image compatibility? Does it follow Universal Blue conventions?

**Violations Requiring Justification**: [List any principle violations with detailed rationale, or state "None"]

## Project Structure

### Documentation (this feature)

```
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)
<!--
  ACTION REQUIRED: For bootc container images, the structure is typically:
  - Containerfile: Image definition
  - build_files/build.sh: Package installations and system modifications
  - build_files/files/: Static files mirroring root filesystem (e.g., etc/, usr/)
  
  Document what parts of this structure your feature modifies.
-->

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

# Feature-Specific Modifications
[Document which files/directories this feature adds or modifies]
# Example:
# - build_files/build.sh: Add `dnf5 install -y new-package`
# - build_files/files/etc/skel/.config/app/: Add app configuration
# - build_files/files/usr/lib/systemd/system/: Add new-service.service
```

**Structure Decision**: [Describe what this feature changes in the bootc container structure and why]

## Complexity Tracking

*Fill ONLY if Constitution Check has violations that must be justified*

No constitution violations identified for this feature. Complexity tracking not required.
