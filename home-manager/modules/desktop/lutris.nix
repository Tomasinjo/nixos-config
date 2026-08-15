{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
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
