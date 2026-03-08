{ config, pkgs, ... }:

let
  rsnapshotServicesConfDaily = pkgs.writeText "rsnapshot-services-daily.conf" ''
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

    backup	/home/tom/scripts/	scripts/
    backup	/home/tom/certs/	certs/
    backup	/home/tom/nixos-config/	nixos-config/
  '';

backupScriptServicesDaily = pkgs.writeShellScriptBin "backup-services-daily" ''
    PATH=$PATH:${pkgs.docker}/bin:${pkgs.rsnapshot}/bin:${pkgs.rsync}/bin:${pkgs.coreutils}/bin:${pkgs.gnugrep}/bin
    
    # Get a list of currently running containers that end with "-db"
    DB_CONTAINERS=$(docker ps --format '{{.Names}}' | grep '\-db$' || true)

    if [ -n "$DB_CONTAINERS" ]; then
      echo "Stopping containers: $(echo $DB_CONTAINERS)"
      docker stop $DB_CONTAINERS
    else
      echo "No running '-db' containers found to stop."
    fi

    if [ "$(date +%w)" -eq 0 ]; then
      echo "It's Sunday - Running rsnapshot weekly..."
      rsnapshot -c ${rsnapshotServicesConfDaily} weekly
    fi

    echo "Running rsnapshot daily..."
    rsnapshot -c ${rsnapshotServicesConfDaily} daily

    if [ -n "$DB_CONTAINERS" ]; then
      echo "Starting containers: $(echo $DB_CONTAINERS)"
      docker start $DB_CONTAINERS
    fi
    
    echo "Backup and restart completed."
  '';
in
{
  # This makes the 'backup-services-daily' command available also in terminal
  environment.systemPackages = [ 
    backupScriptServicesDaily 
    pkgs.rsync
  ];

  # systemd service
  systemd.services.docker-backup = {
    description = "Docker Container Backup Service";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      ExecStart = "${backupScriptServicesDaily}/bin/docker-backup";
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
