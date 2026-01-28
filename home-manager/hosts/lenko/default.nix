{ config, pkgs, inputs, ... }:

{
  imports = [
    ./hyprland.nix
    ./waybar.nix
    ./packages.nix
    ../../modules/firefox.nix
    ../../modules/hypridle.nix
    ../../modules/vscode.nix
  ];
}
