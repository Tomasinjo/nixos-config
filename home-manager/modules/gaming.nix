{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    wine
    protontricks
    (lutris.override {
      extraPkgs = pkgs: [
        wineWowPackages.stable
        winetricks
      ];
    })
    mangohud
    goverlay
  ];
}
