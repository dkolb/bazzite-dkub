# Fixed: 1Password and Chrome Permission Issues After Rebase

## Problem

After rebasing to the bazzite-dkub image, the file `/opt/1Password/1Password-BrowserSupport` was owned by an unknown GID and had incorrect permissions, breaking browser integration for 1Password and Chrome.

## Root Cause

The issue occurred because system groups (`onepassword`, `docker`, `ccache`, etc.) were being created with **dynamically assigned GIDs** using the `-` placeholder in `sysusers.d/*.conf` files.

When you:
1. Build the image → groups get some GID (e.g., 995, 996, 997, etc.)
2. Rebase to the image on your system → `/etc/group` already has these groups with different GIDs
3. Files owned by the "new" GID from the image now show as "unknown group"

Since this is a **personal image** (not a general-purpose distribution), the solution is simple: use the **GIDs that already exist on your system** rather than fighting against them!

## Solution

The fix involves **three** key changes:

### 1. Fixed GID Allocation in `sysusers.d/bazzite-dkub.conf`

Changed from dynamic (`-`) to **fixed GID assignments matching your current system**:

```properties
# OLD (broken):
g     onepassword       -     -     -     -

# NEW (fixed - matches your /etc/group):
g     docker            951   -     -     -
g     onepassword       953   -     -     -
g     ccache            954   -     -     -
```

**Why this works:** These GIDs match what's already on your system (including the `docker:951` from upstream bazzite-dx), so files will always resolve correctly without any migration needed.

**Note:** `onepassword-cli` (GID 956) is installed via Homebrew and doesn't need system group management.

### 2. Pre-create Groups BEFORE Package Installation

Added to `build_files/build.sh` before any `dnf5 install` commands:

```bash
### Pre-create system groups with fixed GIDs before package installation
systemd-sysusers
```

**Why this matters:** This ensures the groups exist with the correct GIDs (951, 953, 954) BEFORE 1Password's RPM post-install script tries to use them.

### 3. Fix Permissions During Build (Not Runtime!)

**CRITICAL**: Since `/usr` is immutable at runtime in bootc/ostree systems, we must fix permissions during the image build in `build.sh`:

```bash
# Install 1Password packages
dnf5 install -y 1password 1password-cli

# Fix permissions DURING BUILD (can't fix at runtime due to immutable /usr)
BROWSER_SUPPORT_PATH="/usr/lib/opt/1Password/1Password-BrowserSupport"
if [ -f "$BROWSER_SUPPORT_PATH" ]; then
  chgrp onepassword "$BROWSER_SUPPORT_PATH"
  chmod g+s "$BROWSER_SUPPORT_PATH"
fi
```

**Why during build?**: 
- `/usr/lib/opt/1Password` is where files actually live
- `/usr` becomes read-only after boot in ostree/bootc systems
- Runtime permission changes would fail
- Must fix permissions while building the image

## Benefits

✅ **Matches existing system** - No conflicts with current group GIDs  
✅ **No migration needed** - GIDs already match what's in `/etc/group`  
✅ **Build-time permission fixing** - Permissions set correctly during image build (before /usr becomes immutable)  
✅ **Simple and clean** - No complex migration scripts needed  
✅ **1Password + Chrome browser integration works** - Correct setgid permissions baked into the image  

## Testing the Fix

After building and rebasing to the new image:

1. Check group GIDs (should match your existing system):
   ```bash
   getent group docker onepassword ccache
   ```
   Should show:
   ```
   docker:x:951:dkub
   onepassword:x:953:
   ccache:x:954:
   ```

2. Check 1Password-BrowserSupport permissions:
   ```bash
   ls -l /opt/1Password/1Password-BrowserSupport
   ```
   Should show:
   ```
   -rwxr-sr-x 1 root onepassword ... /opt/1Password/1Password-BrowserSupport
   ```
   Note the `s` in group permissions (setgid bit).

3. Test browser integration:
   - Open Chrome/Firefox
   - Install 1Password extension
   - Extension should connect to the desktop app automatically

## Files Changed

- ✅ `build_files/files/usr/lib/sysusers.d/bazzite-dkub.conf` - Fixed GID assignments (951, 953, 954)
- ❌ `build_files/files/usr/lib/sysusers.d/onepassword-cli.conf` - Removed (redundant, managed by Homebrew)
- ✅ `build_files/build.sh` - Added `systemd-sysusers` call before package installation + permission fixing
- ✅ `build_files/files/usr/libexec/optfix.sh` - Symlink management only (no runtime permission changes)
- ✅ `README.md` - Documented the fix
- ✅ `AGENTS.md` - Updated troubleshooting guide

## Important Notes

⚠️ **Personal Image GIDs**: This image uses GIDs that match the developer's current system (951, 953, 954). This is intentional for a personal image - it avoids migration complexity and matches upstream bazzite-dx's docker group.

⚠️ **Homebrew-managed packages**: `onepassword-cli` is installed via Homebrew and doesn't need system group management in this image.

⚠️ **Do NOT use `-` for system groups**: Always use fixed GIDs in sysusers.d files for immutable/atomic systems to ensure consistency across rebases.

⚠️ **Order matters**: `systemd-sysusers` MUST run before `dnf5 install` commands so the groups exist when RPM post-install scripts execute.

⚠️ **Build-time vs Runtime**: Permission fixes MUST happen during image build in `build.sh`, not at runtime in `optfix.sh`, because `/usr` is immutable after boot in ostree/bootc systems.
