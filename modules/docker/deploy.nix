{ config, pkgs, ... }:

{
  system.autoUpgrade = {
    enable = true;
    flake = "github:Tomasinjo/nixos-config/master#zenki";
    operation = "switch"; 
    
    flags = [
      "--option" "tarball-ttl" "0" 
    ];
  };

  # disable time based trigger, because i  want it to run ater backup task
  systemd.timers.nixos-upgrade.enable = false;

  systemd.services.nixos-upgrade = {
    wantedBy = [ "docker-backup.service" ];
    after = [ "docker-backup.service" ];
  };
}
