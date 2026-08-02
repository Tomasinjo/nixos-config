{ config, pkgs, vars, ... }:

{
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true; # Useful for HDR or upscaling
  };
  hardware.graphics.enable32Bit = true;

}
