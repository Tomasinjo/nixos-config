{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    wine
    protontricks
    (lutris.override {
      extraPkgs = pkgs: [
        wineWow64Packages.stable
        winetricks
      ];
    })
    mangohud
    goverlay
  ];
}
