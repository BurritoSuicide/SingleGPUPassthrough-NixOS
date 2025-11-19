# NixOS Configuration Improvement Suggestions

## 🔴 Critical Issues

### 1. Security & Stability Risks in `configuration.nix`

**Issue**: Lines 114-119 have dangerous settings:
```nix
nixpkgs.config = {
  permittedInsecurePackages = [ "ventoy-qt5-1.1.05" ];
  allowUnsupportedSystem = true;  # ⚠️ RISKY
  allowBroken = true;              # ⚠️ RISKY
  allow32bit = true;
};
```

**Recommendation**: 
- Remove `allowUnsupportedSystem` and `allowBroken` unless absolutely necessary
- These can lead to broken packages and security vulnerabilities
- If you need broken packages, enable them per-package using overlays

**Fix**:
```nix
nixpkgs.config = {
  permittedInsecurePackages = [ "ventoy-qt5-1.1.05" ];
  allow32bit = true;
};
```

### 2. Deprecated `nixpkgs.config` Usage

**Issue**: `nixpkgs.config` is deprecated in favor of `nixpkgs` options in the module system.

**Recommendation**: Move to flake-based configuration:
```nix
# In flake.nix outputs
nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  specialArgs = { inherit unstablePkgs gitPkgs; };
  modules = [
    ./configuration.nix
    {
      nixpkgs.config.allowUnfree = true;
      nixpkgs.config.permittedInsecurePackages = [ "ventoy-qt5-1.1.05" ];
      nixpkgs.config.allow32bit = true;
    }
    # ... rest
  ];
};
```

### 3. Swap Device Duplication

**Issue**: `swapDevices` is defined in both `configuration.nix` (line 42) and `hardware-configuration.nix` (line 29, empty).

**Recommendation**: Remove from `configuration.nix` and keep only in `hardware-configuration.nix`:
```nix
# hardware-configuration.nix
swapDevices = [{ device = "/swapfile"; size = 16 * 1024; }];
```

## 🟡 Important Improvements

### 4. Hardcoded Paths in Scripts

**Issues**:
- `login-music.sh`: Hardcoded path `/home/scryv/Music/...`
- `sunshine.nix`: Hardcoded `WAYLAND_DISPLAY = "wayland-0"`

**Recommendations**:
- Use `$HOME` or `${config.users.users.scryv.home}` in scripts
- For sunshine, detect `WAYLAND_DISPLAY` dynamically or use systemd environment import

**Fix for login-music.sh**:
```bash
MUSIC_PATH="${HOME}/Music/Culmination - Picayune Dreams Vol. 2.mp3"
```

**Fix for sunshine.nix**:
```nix
systemd.user.services.sunshine = {
  # ... 
  serviceConfig = {
    ExecStart = "${config.security.wrapperDir}/sunshine";
    # Remove hardcoded WAYLAND_DISPLAY, let systemd import it
    Environment = [
      "XDG_SESSION_TYPE=wayland"
    ];
    # Import environment from session
    EnvironmentFile = "-/home/scryv/.config/environment.d/*.conf";
  };
};
```

### 5. GPU Passthrough Module Improvements

**Issues**:
- Hardcoded log paths
- Could use better error handling
- Some redundant checks

**Recommendations**:
- Use `config.services.gpu-passthrough.logDir` option
- Add validation for PCI IDs format
- Improve error messages

### 6. Hyprland Configuration Cleanup

**Issues**:
- Many commented-out lines (lines 7-8, 69-71, 137-141, 144-153, 195-198, 239-243)
- Duplicate bezier definitions (lines 33, 36, 40)
- Inconsistent spacing/formatting

**Recommendations**:
- Remove commented code or move to a separate `hyprland.conf.backup` file
- Consolidate bezier definitions
- Use consistent indentation

### 7. Home Manager Configuration

**Issues**:
- Commented-out code (lines 108, 121)
- Duplicate systemd service definitions for noctalia (in both `home.nix` and `shells/noctalia.nix`)

**Recommendations**:
- Remove commented code
- Consolidate noctalia service definition in one place

### 8. Script Error Handling

**Issues**:
- `gc.sh` uses `sudo` without checking if command exists
- `push.sh` mixes `sudo git` and regular `git`
- Some scripts don't handle missing dependencies

**Recommendations**:
```bash
# Example improvement for gc.sh
if ! command -v sudo >/dev/null 2>&1; then
  echo "Error: sudo not found"
  exit 1
fi
```

### 9. Package Organization

**Issues**:
- Very long `environment.systemPackages` list (lines 129-249)
- Mixing stable and unstable packages without clear organization
- Some packages might be better as user packages

**Recommendations**:
- Split into logical groups using `lib.mkMerge` or separate lists
- Consider moving user-specific packages to `home.packages`
- Add comments for package groups

**Example**:
```nix
environment.systemPackages = with pkgs; [
  # Core system utilities
  fastfetch btop caligula nix-update psutils sysstat
  eza vim wget git micro pciutils fd tree curl gawk jq fzf bc busybox
  
  # Monitoring tools
  radeontop amdgpu_top gcalcli libqalculate
  
  # ... etc
] ++ [
  unstablePkgs.kando
  unstablePkgs.waybar
  # ... etc
];
```

## 🟢 Nice-to-Have Improvements

### 10. Add NixOS Options Documentation

**Recommendation**: Add comments explaining non-obvious configurations:
```nix
# Enable GPU passthrough for single-GPU VFIO setup
# This dynamically binds/unbinds GPU when VM starts/stops
services.gpu-passthrough = {
  enable = true;
  # ...
};
```

### 11. Flake Inputs Pinning

**Current**: Using branch names (`nixos-25.05`, `nixos-unstable`)

**Recommendation**: Consider pinning to specific commits for reproducibility:
```nix
nixpkgs.url = "github:NixOS/nixpkgs/abc123def456...";  # Specific commit
```

### 12. System State Version

**Issue**: `system.stateVersion = "25.05"` - this is a future version

**Recommendation**: Verify this is correct. If you're on 24.11, use that instead.

### 13. Firewall Configuration

**Issue**: Only TCP port 5900 is explicitly opened, but other services (cockpit, sunshine, tailscale) also need ports

**Recommendation**: Document or verify all required ports are handled by service modules

### 14. User Groups

**Issue**: User has many groups (line 103). Some might be redundant.

**Recommendation**: Review and document why each group is needed:
```nix
extraGroups = [
  "networkmanager"  # Network management
  "wheel"           # Sudo access
  "libvirtd"        # Virtualization
  "sunshine"        # Game streaming
  "scryv"           # Custom group?
  "audio"           # Audio access
  "video"           # Video access
  "adbusers"        # Android debugging
  "plugdev"         # USB device access
  "kvm"             # KVM virtualization
  "input"           # Input device access
];
```

### 15. Script Permissions

**Recommendation**: Ensure all scripts in `scripts/` and `hypr/scripts/` are executable. Consider adding to `home.activation`:
```nix
home.activation.makeScriptsExecutable = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
  chmod +x ${config.home.homeDirectory}/.config/hypr/scripts/*.sh
  chmod +x /etc/nixos/scripts/*.sh
'';
```

### 16. Environment Variables

**Issue**: Some environment variables are set in multiple places (hyprland.conf, home.nix)

**Recommendation**: Centralize in `home.sessionVariables` or system-wide `environment.sessionVariables`

### 17. Service Dependencies

**Issue**: Some systemd user services might start before dependencies are ready

**Recommendation**: Review `After` and `Wants` clauses, especially for services that depend on graphical session

### 18. Logging

**Recommendation**: Add structured logging or log rotation for:
- GPU passthrough hooks (`/var/log/libvirt/custom_hooks.log`)
- Sunshine service logs
- Custom script outputs

### 19. Backup Strategy

**Recommendation**: Document or automate backup of:
- `/etc/nixos` (already in git)
- Home manager state
- Important user data

### 20. Testing

**Recommendation**: Consider adding:
- `nixos-rebuild test` before `switch` in update script
- Validation checks in scripts
- Dry-run options for destructive operations

## 📝 Code Quality

### 21. Consistent Formatting

**Recommendation**: Run `nixpkgs-fmt` on all `.nix` files:
```bash
nixpkgs-fmt configuration.nix home.nix flake.nix
```

### 22. Remove Unused Imports

**Recommendation**: Check for unused function arguments and imports

### 23. Type Safety

**Recommendation**: Add type annotations where helpful:
```nix
gpuPciId = mkOption {
  type = types.strMatching "^[0-9a-f]{4}:[0-9a-f]{2}:[0-9a-f]{2}\\.[0-9a-f]$";
  # ...
};
```

## 🔧 Specific File Improvements

### `configuration.nix`
- [ ] Remove `allowBroken` and `allowUnsupportedSystem`
- [ ] Move swap device to hardware-configuration.nix
- [ ] Organize packages into logical groups
- [ ] Add comments for complex configurations

### `home.nix`
- [ ] Remove commented code
- [ ] Consolidate noctalia service definition
- [ ] Add missing git user configuration (commented out)

### `hyprland.conf`
- [ ] Remove commented code
- [ ] Fix duplicate bezier definitions
- [ ] Consistent formatting

### `sunshine.nix`
- [ ] Fix hardcoded WAYLAND_DISPLAY
- [ ] Use environment import from session

### Scripts
- [ ] Add error handling
- [ ] Use `$HOME` instead of hardcoded paths
- [ ] Add shebang consistency check
- [ ] Add input validation

### `gpu-passthrough.nix`
- [ ] Add configurable log directory
- [ ] Add PCI ID format validation
- [ ] Improve error messages

## 🎯 Priority Summary

1. **High Priority**: Fix security issues (#1, #2), remove risky settings
2. **Medium Priority**: Fix hardcoded paths (#4), cleanup code (#6, #7)
3. **Low Priority**: Code organization (#9), documentation (#10), formatting (#21)

