{ config, pkgs, inputs, ... }:

{
  imports = [
    ./packages.nix
    ../../modules/firefox/firefox-base.nix
    ../../modules/firefox/extensions.nix
    ../../modules/firefox/bookmarks.nix
    ../../modules/vscode.nix
    ../../modules/desktop/hyprland-base.nix
    ../../modules/desktop/waybar-base.nix
    ../../modules/desktop/hyprlock.nix
    ../../modules/desktop/cursor.nix
    ../../modules/desktop/hyprpaper.nix
    ../../modules/desktop/kitty.nix
    ../../modules/desktop/rofi.nix
    ../../modules/desktop/hyprsunset.nix
    ../../modules/protonmail-bridge.nix
    ../../modules/thunderbird.nix
  ];
}