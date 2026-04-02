# AGENTS.md - NixOS Configuration Repository

## Verify and find options for packages and services

```bash
# Contains every official option.
# LLM: Use '/' to search keywords inside the pager.
man configuration.nix

# Inspect a specific option path to see current value, default, and description.
# Example: nixos-option services.xserver.enable
nixos-option <OPTION_PATH>

# The modern way to search for packages. 
# Provides descriptions, versions, and attribute paths.
nix search nixpkgs <keyword>

# This is the most powerful method for an agent to "browse" the system tree.
# Run these commands inside: nix repl -f '<nixpkgs/nixos>'
# 
# 1. To see all available keys:  builtins.attrNames options
# 2. To check a specific path:  options.services.ssh
# 3. To see all package names:  builtins.attrNames pkgs
echo "Usage: nix repl -f '<nixpkgs/nixos>'"

# For Home Manager, this is the equivalent manpage for user-level options.
man home-configuration.nix
```

## Build/Test Commands
```bash
# Validate configuration syntax
nix flake check

# Dry-run build for specific host (test without building)
nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel --dry-run

# Test configuration without switching
sudo nixos-rebuild test --flake .

```

## Code Style Guidelines

**Language**: Nix expression language

**Formatting**: Use 2 space indentation

**Imports**: Always import required modules at top: `{ config, lib, pkgs, ... }:` or with additional args like `inputs, outputs, system, timeZone`

**Naming**: Use camelCase for options (`userName`, `hostName`, `isDesktopUser`), kebab-case for hostnames, underscores for module names (`main_user`)

**Module Pattern**: Define options with `lib.mkOption`, use `lib.mkIf` for conditional config, use `lib.mkMerge` for combining attribute sets

**Error Handling**: Rely on Nix's built-in evaluation errors; use `lib.mkEnableOption` for optional features

**Comments**: Minimal comments; prefer self-documenting option descriptions


