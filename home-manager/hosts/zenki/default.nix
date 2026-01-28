{ config, pkgs, inputs, ... }:

{
  imports = [
    ./hyprland.nix
    ./waybar.nix
    ./packages.nix
    ./update-docker.nix
    ../../modules/gaming.nix

  ];
}
