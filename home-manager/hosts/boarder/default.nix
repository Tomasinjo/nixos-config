{ config, pkgs, inputs, ... }:

{
  imports = [
    ./packages.nix
    ../../modules/firefox/firefox-base.nix
    ../../modules/desktop/hyprland-base.nix
    ../../modules/desktop/rofi.nix
  ];
}