{ config, pkgs, inputs, ... }:

{
  imports = [
    ./packages.nix
    ../../modules/shell.nix
    ../../modules/gaming.nix
    ../../modules/desktop/hyprland-base.nix
    ../../modules/desktop/waybar-base.nix
    ../../modules/desktop/hyprlock.nix
    ../../modules/desktop/cursor.nix
    ../../modules/desktop/hyprpaper.nix
    ../../modules/desktop/kitty.nix
    ../../modules/desktop/rofi.nix
  ];

  modules.shell.enableCpuAliases = true;
}
