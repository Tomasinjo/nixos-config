{ config, pkgs, inputs, ... }:

{
  imports = [
    ./packages.nix
    ../../modules/desktop/lutris.nix
    ../../modules/desktop/hyprland/hyprland.nix
    ../../modules/desktop/hyprland/rofi.nix
    ../../modules/desktop/kitty.nix
  ];

  modules.shell.enableCpuAliases = true;
}
