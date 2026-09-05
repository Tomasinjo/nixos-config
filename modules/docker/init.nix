{ pkgs, vars, ... }:

{
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };

  environment.systemPackages = [ pkgs.docker-compose pkgs.ctop ];
  users.users.${vars.username}.extraGroups = [ "docker" ];
}