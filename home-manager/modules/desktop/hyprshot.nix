

{ config, lib, pkgs, vars, ... }:

{
  home.activation.screenshotsDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p ${vars.dir.home}/screenshots
  '';

  home.packages = with pkgs; [ hyprshot ];

}
