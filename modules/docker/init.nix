{ pkgs, vars, ... }:

{
  users.users.docker-user = {
    isSystemUser = true;
    group = "docker-user";
    uid = 1111;
  };
  users.groups.docker-user.gid = 1111;
  users.users.${vars.username}.extraGroups = [ "docker-user" ];

  boot.kernel.sysctl."kernel.perf_event_paranoid" = 0;  # CAP_MON requires this, frigate container  

  imports = [
    ./init_base.nix
    ./network.nix
    ./backup-daily-weekly.nix
    ./backup-quarterly.nix
    ./deploy.nix
    ./vector.nix
  ];
}
