<!--
Sync Impact Report - v1.0.0 (Initial Constitution)
================================================================================
Version: NEW → 1.0.0 (MINOR - Initial establishment of governance framework)
Ratification Date: 2025-10-11
Last Amended: 2025-10-11

Principles Defined:
  - I. Immutability & Base Layer Integrity (NEW)
  - II. Documentation-First Development (NEW)
  - III. Container-Native Workflows (NEW)
  - IV. Automated Testing & CI/CD (NEW)
  - V. Universal Blue Compatibility (NEW)

Sections Added:
  - Core Principles (5 principles defined)
  - Technical Constraints (bootc/ostree specific requirements)
  - Development Workflow (build, test, deploy process)
  - Governance (amendment process and compliance)

Template Alignment Status:
  ✅ plan-template.md - Constitution Check section aligns with all 5 principles
  ✅ spec-template.md - User story format supports incremental testing
  ✅ tasks-template.md - Task organization supports build/test/deploy workflow
  ✅ No agent-specific references (CLAUDE, etc.) - uses generic guidance

Follow-up Actions:
  - None - All placeholders resolved with concrete values
  - Templates already aligned with bootc container development workflow

Commit Message:
  docs: establish constitution v1.0.0 (bootc container governance framework)
================================================================================
-->

# bazzite-dkub Constitution

## Core Principles

### I. Immutability & Base Layer Integrity

**MUST preserve the immutable nature of the base image and ostree filesystem:**

- Base system (`/usr`) is read-only and MUST NOT be modified at runtime
- All customizations MUST be applied as container image layers during build
- Software installing to `/opt` MUST use the optfix pattern (`/usr/lib/opt` + symlinks)
- User-specific files MUST be placed in `/etc/skel/`, never directly in `/var` or `/home`
- Static configuration files MUST be organized in `build_files/files/` mirroring the root filesystem structure

**Rationale**: OSTree's immutability provides atomic updates, rollback capabilities, and known-good states. Breaking this model eliminates the core benefits of bootc-based systems and can render the system unbootable.

### II. Documentation-First Development

**MUST document every customization before, during, and after implementation:**

- All package additions MUST be documented in both `README.md` and `AGENTS.md`
- Every installation command in `build.sh` MUST include inline comments explaining the purpose
- Breaking changes or deprecations MUST be documented in commit messages and release notes
- Installation procedures MUST be tested by following the documentation exactly as written
- Code and documentation MUST be committed together in the same change

**Rationale**: Container images are black boxes - documentation is the only way future maintainers (including yourself) can understand customizations. Documentation drift leads to configuration entropy and maintenance burden.

### III. Container-Native Workflows

**MUST use container-based build, test, and deployment processes:**

- All builds MUST happen via `podman`/`buildah` using the `Containerfile`
- Package management MUST use `dnf5` (preferred over `dnf` for performance)
- All images MUST be signed with Cosign for security verification
- Images MUST be published to a container registry (GHCR)
- Multi-architecture support MUST be considered (amd64 primary, arm64 when feasible)
- Build commands MUST be exposed via `just` recipes for consistency

**Rationale**: Container-native workflows leverage industry-standard tooling, enable CI/CD automation, and align with Universal Blue's cloud-native philosophy. This ensures reproducible builds and supply chain security.

### IV. Automated Testing & CI/CD

**MUST validate changes locally before pushing, with CI/CD as safety net:**

- All changes MUST be tested locally with `just build` before committing
- Shell scripts MUST pass `just lint` (ShellCheck validation)
- GitHub Actions MUST run on every push to `main` and pull request
- Build failures in CI MUST block merging
- Optional: VM/ISO testing with `just build-qcow2` and `just run-vm-qcow2` for major changes
- All builds MUST pass `bootc container lint` validation

**Rationale**: Local testing catches issues early and reduces CI/CD iterations. Automated validation prevents regressions and ensures every commit produces a valid, bootable image. Pre-merge validation is critical for immutable systems where runtime fixes are not possible.

### V. Universal Blue Compatibility

**MUST maintain compatibility with Universal Blue ecosystem and base images:**

- Base image MUST be a Universal Blue image (currently `ghcr.io/ublue-os/bazzite-dx:stable`)
- MUST follow Universal Blue conventions for file organization and systemd services
- MUST use `ujust` recipes where appropriate (extensible via `/usr/share/ublue-os/just/*.just`)
- Breaking changes to base image APIs MUST be identified and adapted to within one release cycle
- Community best practices from Universal Blue forums/Discord MUST be considered

**Rationale**: Universal Blue provides the foundation, community support, and update infrastructure. Diverging from ecosystem conventions creates maintenance burden and breaks compatibility with shared tooling and knowledge base.

## Technical Constraints

### Technology Stack
- **Base Image**: `ghcr.io/ublue-os/bazzite-dx:stable` (Universal Blue)
- **Container Runtime**: Podman/Buildah (rootless when possible)
- **Package Manager**: `dnf5` (required), `rpm-ostree` (runtime layering)
- **Build System**: `just` command runner for task automation
- **CI/CD**: GitHub Actions with automated signing via Cosign
- **Image Builder**: `bootc-image-builder` for ISO/VM disk images

### Filesystem Requirements
- `/usr` is immutable - no direct modifications allowed
- `/etc` can be customized via files in `build_files/files/etc/`
- `/var` is mutable at runtime but MUST be clean in base image
- `/opt` installations MUST use optfix pattern: `/usr/lib/opt/<app>` + symlink from `/var/opt/<app>`
- User home directory templates MUST use `/etc/skel/` for per-user files

### Package Management Rules
- Use `dnf5 install -y <package>` for new packages
- Use `dnf5 update -y <package>` for updates
- Use `--nogpgcheck` ONLY when GPG signatures are known to be broken (e.g., VS Code - document reason)
- Always run `dnf5 clean all` at end of `build.sh` to reduce image size
- Remove `/var/lib/dnf` and `/var/cache/dnf` after package operations

### Security Requirements
- All container images MUST be signed with Cosign
- Private signing keys MUST stay in GitHub Secrets, never committed
- Repository keys MUST be imported before installing third-party packages
- SELinux policies MUST NOT be disabled (adjust policies if needed)

## Development Workflow

### Making Changes

1. **Plan**: Identify what packages/configs need to be added or modified
2. **Edit**: Update `build_files/build.sh` for package installations OR add files to `build_files/files/`
3. **Document**: Update `README.md` and `AGENTS.md` in the same commit
4. **Test Locally**: Run `just build` to verify the image builds successfully
5. **Validate**: Run `just lint` if shell scripts were modified
6. **Optional Testing**: Run `just build-qcow2 && just run-vm-qcow2` for major changes
7. **Commit**: Commit code and docs together with descriptive message
8. **Push**: Push to `main` - CI/CD will build, sign, and publish automatically

### Quality Gates

- **Pre-commit**: Local build must succeed (`just build`)
- **Pre-commit**: ShellCheck must pass (`just lint`) if shell scripts modified
- **Pre-push**: All documentation must be updated
- **CI/CD**: GitHub Actions build must succeed
- **CI/CD**: Container signing must complete
- **Post-deploy**: Image must be pullable from GHCR

### Rollback Process

If a bad image is published:
1. Identify last known-good image tag from GHCR
2. Users can rollback with: `sudo bootc switch ghcr.io/dkolb/bazzite-dkub:<good-tag>`
3. Fix the issue in a new commit
4. Document the issue and resolution in commit message

## Governance

### Amendment Process

This constitution may be amended when:
- New Universal Blue conventions emerge that require adoption
- bootc/ostree upstream changes necessitate workflow updates
- Consistent pain points indicate a principle needs refinement
- New categories of customizations require additional principles

**Amendment Procedure**:
1. Propose changes via GitHub Issue with rationale
2. Update `.specify/memory/constitution.md` with new version
3. Update dependent templates (plan, spec, tasks) for consistency
4. Increment version per semantic versioning:
   - **MAJOR**: Backward-incompatible changes (removing/redefining principles)
   - **MINOR**: New principles or material expansions
   - **PATCH**: Clarifications, wording fixes, non-semantic changes
5. Document changes in Sync Impact Report (HTML comment at top of file)
6. Commit with message: `docs: amend constitution to vX.Y.Z (<summary>)`

### Compliance & Review

- All changes to `Containerfile` or `build_files/` MUST be reviewed against these principles
- Pull requests MUST include justification if violating any principle
- Complexity that contradicts simplicity principle MUST be explicitly justified
- Template usage (plan, spec, tasks) MUST reference this constitution for validation

### Related Documentation

- **Runtime Guidance**: `AGENTS.md` - AI agent instructions for development
- **User Documentation**: `README.md` - User-facing features and quick start
- **Build Commands**: `Justfile` - Available build/test/deploy commands
- **CI/CD Pipeline**: `.github/workflows/build.yml` - Automated build process

**Version**: 1.0.0 | **Ratified**: 2025-10-11 | **Last Amended**: 2025-10-11