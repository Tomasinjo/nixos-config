{ config, pkgs, ... }:

{
  networking.networkmanager.enable = true;

  networking.firewall = {
    enable = true;
    allowPing = true;
    allowedTCPPortRanges = [ { from = 1714; to = 1764; } ];  # kde connect
    allowedUDPPortRanges = [ { from = 1714; to = 1764; } ];  # kde connect
 };
}
