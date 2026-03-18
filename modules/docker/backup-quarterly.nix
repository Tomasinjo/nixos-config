{ config, pkgs, vars, ... }:

let
  rsnapshotServicesQuarterly = pkgs.writeText "rsnapshot-services-quarterly.conf" ''
    config_version	1.2

    snapshot_root	${vars.dir.usb_mountpoint}/services

    retain	quarterly	4
    interval	quarterly	1

    cmd_cp	${pkgs.coreutils}/bin/cp
    cmd_rm	${pkgs.coreutils}/bin/rm
    cmd_rsync	${pkgs.rsync}/bin/rsync
    cmd_logger	${pkgs.util-linux}/bin/logger
    cmd_du	${pkgs.coreutils}/bin/du

    rsync_long_args	--archive --delete --numeric-ids

    backup	${vars.dir.scripts}/	scripts/
    backup	${vars.dir.certs}/	certs/
    backup	${vars.dir.nixos_config}/	nixos-config/
  '';

  backupScriptServicesQuarterly = pkgs.writeShellScriptBin "backup-services-quarterly" ''
    PATH=$PATH:${pkgs.docker}/bin:${pkgs.rsnapshot}/bin:${pkgs.rsync}/bin:${pkgs.coreutils}/bin:${pkgs.gnugrep}/bin:${pkgs.systemd}/bin:${pkgs.gawk}/bin
    
    # Get a list of currently running containers that end with "-db"
    DB_CONTAINERS=$(docker ps --format '{{.Names}}' | grep '\-db$' || true)

    if [ -n "$DB_CONTAINERS" ]; then
      DB_SERVICES=$(echo "$DB_CONTAINERS" | awk '{print "docker-"$1".service"}')
      echo "Stopping services: $(echo $DB_SERVICES)"
      systemctl stop $DB_SERVICES
    else
      echo "No running '-db' containers found to stop."
    fi

    echo "Running apps rsnapshot quarterly..."
    rsnapshot -c ${rsnapshotServicesQuarterly} quarterly

    if [ -n "$DB_CONTAINERS" ]; then
      echo "Starting services: $(echo $DB_SERVICES)"
      systemctl start $DB_SERVICES
    fi
    
    echo "Backup and restart completed."
  '';
in
{
  environment.systemPackages = [ 
    backupScriptServicesQuarterly  # This makes the 'backup-services-quarterly' command available in terminal
    pkgs.rsync
  ];
}
