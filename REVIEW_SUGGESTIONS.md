# Configuration Review - Suggested Improvements

## 🔴 High Priority

### 1. Remove Empty Lines and Improve Formatting

**Issues:**
- `configuration.nix` line 165: Extra blank line
- `configuration.nix` line 178: Extra blank line
- `home.nix` line 44: Extra blank line
- `home.nix` line 79: Extra blank line

**Recommendation:** Remove unnecessary blank lines for cleaner code.

### 2. Consolidate Duplicate Shell Imports in home.nix

**Issue:** Lines 11-13 use `builtins.path` three times for the same directory.

**Current:**
```nix
imports = [
  ./modules/quickshell.nix
  (let shellsSrc = builtins.path { path = ./shells; name = "shells"; }; in shellsSrc + "/caelestia.nix")
  (let shellsSrc = builtins.path { path = ./shells; name = "shells"; }; in shellsSrc + "/dankmaterial.nix")
  (let shellsSrc = builtins.path { path = ./shells; name = "shells"; }; in shellsSrc + "/noctalia.nix")
];
```

**Suggested:**
```nix
imports = [
  ./modules/quickshell.nix
] ++ (let shellsSrc = builtins.path { path = ./shells; name = "shells"; }; in [
  (shellsSrc + "/caelestia.nix")
  (shellsSrc + "/dankmaterial.nix")
  (shellsSrc + "/noctalia.nix")
]);
```

### 3. Unused Variables in home.nix

**Issue:** Lines 4-6 define variables that may not be used:
- `hyprctlBin` - defined but not used
- `jqBin` - defined but not used  
- `caelestiaCliBin` - may be used in shells, but not directly in home.nix

**Recommendation:** Remove if unused, or move to where they're actually needed.

### 4. Git Configuration Missing

**Issue:** `home.nix` line 40-42 has git enabled but no user configuration.

**Current:**
```nix
programs.git = {
  enable = true;
};
```

**Recommendation:** Add user name and email (or document why they're not set):
```nix
programs.git = {
  enable = true;
  userName = "scryv";  # or your actual name
  userEmail = "your.email@example.com";
};
```

### 5. Sunshine Service Duplication

**Issue:** `sunshine` is defined in both:
- `configuration.nix` lines 141-146 (system service)
- `sunshine/sunshine.nix` (user service)

**Recommendation:** Document which one is used, or consolidate. The system service in `configuration.nix` seems redundant if you're using the module.

### 6. Firewall Port Documentation

**Issue:** `configuration.nix` line 196 only opens port 5900, but other services (cockpit, sunshine, tailscale) also need ports.

**Recommendation:** Document that these are handled by service modules, or explicitly list all required ports for clarity.

## 🟡 Medium Priority

### 7. Package Organization Improvements

**Issues:**
- `packages/system/wayland.nix`: Mixes stable and unstable packages. Consider splitting or better organization.
- `packages/user/dev.nix`: `unstablePkgs` parameter is accepted but not used (only uses stable `vscode`).
- Some packages might be better categorized (e.g., `sassc` in media.nix is a CSS compiler, not really media-related).

**Recommendations:**
- Consider splitting wayland.nix into `wayland.nix` (stable) and `wayland-unstable.nix`
- Remove unused `unstablePkgs` from `dev.nix` or use it for unstable dev tools
- Move `sassc` to a more appropriate category or create a `build-tools.nix`

### 8. GPU Passthrough Module Hardcoded Values

**Issue:** `gpu-passthrough.nix` has hardcoded log paths and could benefit from configurable options.

**Recommendation:** Add options for:
- Log directory location
- PCI ID format validation
- Better error messages

### 9. Hyprland Configuration

**Issues:**
- Line 130: Hardcoded path `~/Prowler.m4a` - should use `$HOME`
- Line 147: Complex fluidsynth command with store path discovery - could be simplified
- Some inconsistent spacing

**Recommendations:**
- Use `$HOME` instead of `~`
- Consider creating a wrapper script for the fluidsynth command
- Standardize spacing

### 10. Script Error Handling

**Issues:**
- `scripts/gc.sh`: Uses `sudo` without checking if command exists
- `scripts/push.sh`: Mixes `sudo git` and regular `git`
- `scripts/update.sh`: Complex user detection logic could be simplified

**Recommendations:**
- Add command existence checks
- Standardize git usage (use sudo consistently or not)
- Consider extracting user detection to a function

### 11. Flake Input Warning

**Issue:** Warning about `noctalia` having override for non-existent input `quickshell`.

**Current:** `flake.nix` line 35 has `inputs.quickshell.follows = "quickshell"` but the input might not be properly connected.

**Recommendation:** Verify the input chain is correct. The warning suggests the override might not be needed or the input name is wrong.

### 12. System State Version

**Issue:** `system.stateVersion = "25.05"` - This is a future version. Verify this is correct for your current NixOS version.

**Recommendation:** Check your actual NixOS version and ensure stateVersion matches.

## 🟢 Low Priority / Nice-to-Have

### 13. Documentation Improvements

**Recommendations:**
- Add comments explaining non-obvious configurations (GPU passthrough, complex services)
- Document why certain packages are in system vs user
- Add README sections explaining the package organization structure

### 14. Code Formatting

**Recommendation:** Run `nixpkgs-fmt` on all `.nix` files for consistent formatting:
```bash
nixpkgs-fmt configuration.nix home.nix flake.nix packages/**/*.nix
```

### 15. Type Safety

**Recommendation:** Add type annotations where helpful, especially in custom modules:
```nix
gpuPciId = mkOption {
  type = types.strMatching "^[0-9a-f]{4}:[0-9a-f]{2}:[0-9a-f]{2}\\.[0-9a-f]$";
  # ...
};
```

### 16. Package Comments

**Recommendation:** Some package files could benefit from more descriptive comments explaining what each package does, especially in categories like `sysutil.nix` where there are many packages.

### 17. Environment Variables

**Issue:** Some environment variables are set in multiple places (hyprland.conf, home.nix).

**Recommendation:** Consider centralizing in `home.sessionVariables` or system-wide `environment.sessionVariables`.

### 18. Service Dependencies

**Recommendation:** Review systemd service dependencies, especially for services that depend on graphical session. Some might benefit from `Wants` in addition to `After`.

### 19. Logging and Monitoring

**Recommendation:** Consider adding:
- Log rotation for GPU passthrough hooks
- Structured logging for custom scripts
- Health checks for critical services

### 20. Backup Strategy

**Recommendation:** Document or automate backup of:
- `/etc/nixos` (already in git ✓)
- Home Manager state
- Important user data

## 📝 Specific File Improvements

### `configuration.nix`
- [ ] Remove extra blank lines (165, 178)
- [ ] Document firewall port handling
- [ ] Review sunshine service duplication
- [ ] Verify system.stateVersion

### `home.nix`
- [ ] Consolidate shell imports
- [ ] Remove unused variables or use them
- [ ] Add git user configuration
- [ ] Remove extra blank lines (44, 79)

### `flake.nix`
- [ ] Fix noctalia input warning
- [ ] Consider adding flake description

### `packages/system/wayland.nix`
- [ ] Consider splitting stable/unstable packages
- [ ] Add more descriptive comments

### `packages/user/dev.nix`
- [ ] Remove unused `unstablePkgs` or use it

### `hyprland.conf`
- [ ] Fix hardcoded `~/Prowler.m4a` path
- [ ] Simplify fluidsynth command
- [ ] Standardize spacing

### Scripts
- [ ] Add error handling
- [ ] Standardize git usage
- [ ] Extract common functions

## 🎯 Priority Summary

1. **High Priority**: Formatting cleanup, consolidate imports, fix unused variables, add git config
2. **Medium Priority**: Package organization improvements, script error handling, fix flake warnings
3. **Low Priority**: Documentation, code formatting, type safety, monitoring

