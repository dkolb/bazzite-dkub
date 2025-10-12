# Implementation Plan: [FEATURE]

**Branch**: `[###-feature-name]` | **Date**: [DATE] | **Spec**: [link]
**Input**: Feature specification from `/specs/[###-feature-name]/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

[Extract from feature spec: primary requirement + technical approach from research]

## Technical Context

<!--
  ACTION REQUIRED: Replace the content in this section with the technical details
  for this feature in the context of a bootc container image.
-->

**Base Image**: `ghcr.io/ublue-os/bazzite-dx:stable` (or specify if different)  
**Package Manager**: `dnf5` (required for all package installations)  
**Container Runtime**: Podman/Buildah  
**Primary Build Tool**: `just` (command runner)  
**Image Registry**: `ghcr.io/dkolb/bazzite-dkub`  
**Testing Method**: [e.g., `just build`, `just build-qcow2 && just run-vm-qcow2`, or NEEDS CLARIFICATION]  
**Deployment Target**: [e.g., bootc-based system, VM, ISO installation, or NEEDS CLARIFICATION]  
**Filesystem Constraints**: [e.g., modifies `/etc` only, uses optfix for `/opt`, `/var` clean, or NEEDS CLARIFICATION]  
**Build Phase**: [e.g., `build.sh` package installation, static file copy, systemd service enable, or NEEDS CLARIFICATION]  
**Performance Goals**: [domain-specific, e.g., image size <2GB, build time <10min, or NEEDS CLARIFICATION]  
**Integration Requirements**: [e.g., must work with existing GearLever setup, 1Password integration, or N/A]

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

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
