{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    git
    fd
    fastfetch
    kitty
    pavucontrol
    yazi
    cliphist
    exiftool
    discord
  ];
}
