{ config, pkgs, inputs, ... }:

{
  imports = [
    ./packages.nix
    ../../modules/desktop/firefox/firefox-base.nix
    ../../modules/desktop/firefox/extensions.nix
    ../../modules/desktop/firefox/bookmarks.nix
    ../../modules/desktop/vscode.nix
    ../../modules/desktop/niri/niri.nix
    ../../modules/desktop/niri/noctalia.nix
    ../../modules/desktop/kitty.nix
    ../../modules/desktop/obs_studio.nix
    ../../modules/yazi.nix
  ];

}
