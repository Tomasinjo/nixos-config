{ config, pkgs, ... }:

let
  backupScript = pkgs.writeShellScriptBin "docker-backup" ''
    # Make sure required tools are in the script's PATH
    PATH=$PATH:${pkgs.docker}/bin:${pkgs.rsnapshot}/bin:${pkgs.rsync}/bin:${pkgs.coreutils}/bin

    containers=(
      "mongo-unifi"
      "db_paperless"
      "compreface-postgres-db"
      "double-take"
      "frigate"
      "nextcloud-db"
      "immich_postgres"
      "teslamate-db"
      "grafana-teslamate"
      "music-assistant"
      "jellyfin"
      "radarr"
      "db-umami"
      "fafi_db"
      "metabase-db"
      "vaultwarden"
    )

    echo "Stopping containers..."
    for container in "''${containers[@]}"; do
      docker stop "$container"
    done

    echo "Backing up..."
    # Note: Ensure this path is correct and accessible by root
    rsnapshot -c /home/tom/scripts/backups/rsnapshot.conf daily

    # Run weekly on Sundays
    if [[ $(date +%w) -eq 0 ]]; then
      rsnapshot -c /home/tom/scripts/backups/rsnapshot.conf weekly
    fi

    echo "Starting containers..."
    for container in "''${containers[@]}"; do
      docker start "$container"
    done

    echo "Backup and restart completed."
  '';
in
{
  # This makes the 'docker-backup' command available also in terminal
  environment.systemPackages = [ backupScript ];

  # systemd service
  systemd.services.docker-backup = {
    description = "Docker Container Backup Service";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      ExecStart = "${backupScript}/bin/docker-backup";
    };
  };

  # 3. triger for service
  systemd.timers.docker-backup = {
    description = "Timer for Docker Container Backup";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "04:00";
      Persistent = true;
    };
  };
}