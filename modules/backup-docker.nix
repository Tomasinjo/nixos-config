{ config, pkgs, ... }:

let
  containers = [
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
    "db_ha"
    "db-lightdash"
    "nocodb"
  ];

  rsnapshotConf = pkgs.writeText "rsnapshot.conf" ''
    config_version	1.2

    snapshot_root	/hoarder-data/backup/

    retain	daily	4
    retain	weekly	6

    cmd_cp	${pkgs.coreutils}/bin/cp
    cmd_rm	${pkgs.coreutils}/bin/rm
    cmd_rsync	${pkgs.rsync}/bin/rsync
    cmd_logger	${pkgs.util-linux}/bin/logger
    cmd_du	${pkgs.coreutils}/bin/du

    rsync_long_args	-a	--delete
s
    backup	/home/tom/apps/arrs/	apps/arrs/
    backup	/home/tom/apps/blog/	apps/blog/
    backup	/home/tom/apps/fafi/	apps/fafi/
    backup	/home/tom/apps/ha/	apps/ha/	exclude=/esphome/config/.esphome/
    backup	/home/tom/apps/immich/	apps/immich/
    backup	/home/tom/apps/nextcloud/	apps/nextcloud/
    backup	/home/tom/apps/nvr/	apps/nvr/
    backup	/home/tom/apps/paperless/	apps/paperless/
    backup	/home/tom/apps/samba/	apps/samba/
    backup	/home/tom/apps/pgadmin/	apps/pgadmin/
    backup	/home/tom/apps/searxng/	apps/searxng/
    backup	/home/tom/apps/traefik/	apps/traefik/
    backup	/home/tom/apps/trilium/	apps/trilium/
    backup	/home/tom/apps/unifi/	apps/unifi/
    backup	/home/tom/apps/vaultwarden/	apps/vaultwarden/

    backup	/home/tom/apps/docker-compose.yml	apps/docker-compose.yml

    backup	/home/tom/scripts/	scripts/
    backup	/home/tom/certs/	certs/
    backup	/home/tom/nixos-config/	nixos-config/
  '';

  backupScript = pkgs.writeShellScriptBin "docker-backup" ''
    PATH=$PATH:${pkgs.docker}/bin:${pkgs.rsnapshot}/bin:${pkgs.rsync}/bin:${pkgs.coreutils}/bin
    echo "Stopping containers: ${builtins.concatStringsSep " " containers}"
    docker stop ${builtins.concatStringsSep " " containers}

    # Logic for weekly: If Sunday (0), run weekly
    if [ "$(date +%w)" -eq 0 ]; then
      echo "It's Sunday - Running rsnapshot weekly..."
      rsnapshot -c ${rsnapshotConf} weekly
    fi

    echo "Running rsnapshot daily..."
    rsnapshot -c ${rsnapshotConf} daily

    echo "Starting containers..."
    docker start ${builtins.concatStringsSep " " containers}
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

  systemd.timers.docker-backup = {
    description = "Timer for Docker Container Backup";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "04:00";
      Persistent = true;
    };
  };
}
