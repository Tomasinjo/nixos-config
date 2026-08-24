{ pkgs, vars, ... }:

{
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
    
    daemon.settings = {
      data-root = vars.dir.docker_root;
      default-address-pools = [
        {
          base = "10.200.0.0/16";
          size = 24;
        }
      ];
    };
  };

  environment.systemPackages = [ pkgs.docker-compose pkgs.ctop ];
  users.users.${vars.username}.extraGroups = [ "docker" ];
}
