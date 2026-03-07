{ config, pkgs, ... }:

### INSTRUCTIONS ###
# najdes device
# lsblk | grep 4.5T

### mount disk
# sudo mount -t ext4 /dev/sdx /home/tom/mnt/

### go to screen
# screen -S backup

### restore screen
# screen -r backup

# remove screen: ctrl + a + k
# leave screen: ctrl + a + d
# list screens: screen -ls

### run rsnapshot
# sudo backup-quarterly

let
  rsnapshotServicesConf = pkgs.writeText "rsnapshot-services.conf" ''
    config_version	1.2

    snapshot_root	/home/tom/mnt/services

    retain	quarterly	4

    interval	quarterly	1

    cmd_cp	${pkgs.coreutils}/bin/cp
    cmd_rm	${pkgs.coreutils}/bin/rm
    cmd_rsync	${pkgs.rsync}/bin/rsync
    cmd_logger	${pkgs.util-linux}/bin/logger
    cmd_du	${pkgs.coreutils}/bin/du

    rsync_long_args	--archive --delete --numeric-ids

    backup	/home/tom/scripts/	scripts/
    backup	/home/tom/certs/	certs/
    backup	/home/tom/nixos-config/	nixos-config/
  '';

  rsnapshotImportantConf = pkgs.writeText "rsnapshot-important.conf" ''
    config_version	1.2

    snapshot_root	/home/tom/mnt/important-data

    retain	quarterly	4

    interval	quarterly	1

    cmd_rsync	${pkgs.rsync}/bin/rsync
    rsync_long_args	--archive --delete --numeric-ids

    backup	/impo-data/	important-data/
  '';

  backupScript = pkgs.writeShellScriptBin "backup-quarterly" ''
    PATH=$PATH:${pkgs.docker}/bin:${pkgs.rsnapshot}/bin:${pkgs.rsync}/bin:${pkgs.coreutils}/bin:${pkgs.gnugrep}/bin
    
    # Get a list of currently running containers that end with "-db"
    DB_CONTAINERS=$(docker ps --format '{{.Names}}' | grep '\-db$' || true)

    if [ -n "$DB_CONTAINERS" ]; then
      echo "Stopping containers: $(echo $DB_CONTAINERS)"
      docker stop $DB_CONTAINERS
    else
      echo "No running '-db' containers found to stop."
    fi

    echo "Running apps rsnapshot quarterly..."
    rsnapshot -c ${rsnapshotServicesConf} quarterly

    echo "Running data rsnapshot quarterly..."
    rsnapshot -c ${rsnapshotImportantConf} quarterly

    if [ -n "$DB_CONTAINERS" ]; then
      echo "Starting containers: $(echo $DB_CONTAINERS)"
      docker start $DB_CONTAINERS
    fi
    
    echo "Backup and restart completed."
  '';
in
{
  environment.systemPackages = [ 
    backupScript  # This makes the 'backup-quarterly' command available in terminal
  ];
}
