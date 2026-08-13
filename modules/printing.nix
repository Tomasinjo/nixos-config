
{ config, pkgs, vars, ... }:

{
  services.printing = {
    enable = true;
    # epson-escpr for L3150.
    drivers = [ pkgs.epson-escpr ];
  };

  hardware.sane = {
    enable = true;
    extraBackends = [ pkgs.epkowa ];
  };

  # to add a printer
  # go to http://localhost:631/
  # add new, lpd://printer.xxx.xx:515/PASSTHRU
  # select L3150 series
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  users.users.${vars.username} = {
    extraGroups = [ "lp" "scanner" ];
  };

}
