{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    wineWow64Packages.staging
    winetricks
  ];
}
