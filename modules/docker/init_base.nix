{ pkgs, vars, ... }:

{
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
    
    daemon.settings = {
      data-root = vars.dir.docker_root;
    };
  };

  environment.systemPackages = [ pkgs.docker-compose pkgs.ctop ];
  users.users.${vars.username}.extraGroups = [ "docker" ];
}
