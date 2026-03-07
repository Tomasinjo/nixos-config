{ pkgs, ... }:

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

  users.users.docker-user = {
    isSystemUser = true;
    group = "docker-user";
    uid = 1111;
  };
  users.groups.docker-user.gid = 1111;
  boot.kernel.sysctl."kernel.perf_event_paranoid" = 0;  # CAP_MON requires this, frigate container  
  environment.systemPackages = [ pkgs.docker-compose pkgs.ctop ];
  users.users.tom.extraGroups = [ "docker" "docker-user" ];

  imports = [
    ./network.nix
    ./auto-deploy.nix
  ];
}
