{ config, pkgs, ... }:

{
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true; # Useful for HDR or upscaling
  };

  programs.gamemode.enable = true;

  hardware.graphics.enable32Bit = true;
}
