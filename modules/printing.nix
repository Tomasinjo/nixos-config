
{ config, pkgs, ... }:

{
  services.printing = {
    enable = true;
    # epson-escpr for L3150.
    drivers = [ pkgs.epson-escpr ];
  };

  # scanning
  hardware.sane = {
    enable = true;
    extraBackends = [ pkgs.epkowa ];
  };

  # available at http://localhost:631/
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  users.users.tom = {
    extraGroups = [ "lp" "scanner" ];
  };

}
