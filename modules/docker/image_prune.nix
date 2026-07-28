{ config, pkgs, ... }:

let
  imagePruneScript = pkgs.writeShellScriptBin "docker-image-prune" ''
    PATH=$PATH:${pkgs.docker}/bin:${pkgs.coreutils}/bin

    echo "Starting Docker image prune at $(date)"
    docker image prune -f -a
    echo "Docker image prune completed at $(date)"
  '';
in
{
  environment.systemPackages = [ imagePruneScript ];

  systemd.services.docker-image-prune = {
    description = "Docker Image Prune Service";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      ExecStart = "${imagePruneScript}/bin/docker-image-prune";
      StandardOutput = "journal+console";
      StandardError = "journal+console";
    };
  };

  systemd.timers.docker-image-prune = {
    description = "Timer for Docker Image Prune";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "Wed *-*-* 03:00:00";
      Persistent = true;
    };
  };
}
