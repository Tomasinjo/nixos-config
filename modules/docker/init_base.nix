{ pkgs, vars, ... }:

{
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
    
    daemon.settings = {
      data-root = vars.dir.docker_root;
      default-address-pools = [
        {
          base = "172.17.0.0/12";
          size = 24;
        }
      ];
    };
  };

  environment.systemPackages = [ pkgs.docker-compose pkgs.ctop ];
  users.users.${vars.username}.extraGroups = [ "docker" ];
}
