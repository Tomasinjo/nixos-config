{ config, pkgs, ... }:

### INSTRUCTIONS ###
# najdes device
# lsblk | grep 4.5T

### mount disk
# sudo mount -t exfat /dev/sde2 /mnt/usb_backup/

### go to screen
# screen -S backup

### restore screen
# screen -r backup

# remove screen: ctrl + a + k
# leave screen: ctrl + a + d
# list screens: screen -ls

### run rsnapshot
# sudo backup-quarterly

### monitor progress
# sudo btop     <- must run as sudo to see disk rw
# F4 to filter
# filter by rsync 
###########################

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

  rsnapshotServicesConf = pkgs.writeText "rsnapshot-services.conf" ''
    config_version	1.2

    snapshot_root	/mnt/usb_backup/services

    retain	quarterly	4

    interval	quarterly	1

    cmd_cp	${pkgs.coreutils}/bin/cp
    cmd_rm	${pkgs.coreutils}/bin/rm
    cmd_rsync	${pkgs.rsync}/bin/rsync
    cmd_logger	${pkgs.util-linux}/bin/logger
    cmd_du	${pkgs.coreutils}/bin/du

    rsync_long_args	--archive --delete --numeric-ids
    logfile	/home/tom/scripts/backups/external_disk_backups/rsnapshot.log

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

  rsnapshotImportantConf = pkgs.writeText "rsnapshot-important.conf" ''
    config_version	1.2

    snapshot_root	/mnt/usb_backup/important-data

    retain	quarterly	4

    interval	quarterly	1

    cmd_rsync	${pkgs.rsync}/bin/rsync
    rsync_long_args	--archive --delete --numeric-ids

    backup	/important-data/	important-data/
  '';

  backupScript = pkgs.writeShellScriptBin "backup-quarterly" ''
    echo "Stopping containers: ${builtins.concatStringsSep " " containers}"
    docker stop ${builtins.concatStringsSep " " containers}

    echo "Running rsnapshot quarterly..."
    rsnapshot -c ${rsnapshotServicesConf} quarterly

    echo "Starting containers..."
    docker start ${builtins.concatStringsSep " " containers}
    echo "Backup and restart completed."
  '';
in
{
  # This makes the 'backup-quarterly' command available in terminal
  environment.systemPackages = [ backupScript ];
}
