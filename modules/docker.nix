{ config, pkgs, ... }:

{
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
    
    daemon.settings = {
      data-root = "/home/tom/docker";
      default-address-pools = [
        {
          base = "172.17.0.0/12";
          size = 24;
        }
      ];
    };
  };

  environment.systemPackages = [ pkgs.docker-compose pkgs.ctop ];
  users.users.tom.extraGroups = [ "docker" ];
}
