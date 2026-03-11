{ config, pkgs, inputs, ... }:

{
  imports = [
    ./packages.nix
    ../../modules/firefox.nix
    ../../modules/vscode.nix
    ../../modules/desktop/hyprland-base.nix
  ];
}