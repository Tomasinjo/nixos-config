{ config, pkgs, inputs, ... }:

{
  imports = [
    ./packages.nix
    ../../modules/desktop/firefox/firefox-base.nix
    ../../modules/desktop/firefox/extensions.nix
    ../../modules/desktop/vscode.nix
    ../../modules/desktop/niri/niri.nix
    ../../modules/desktop/niri/noctalia.nix
    ../../modules/desktop/kitty.nix
    ../../modules/yazi.nix
  ];

}
