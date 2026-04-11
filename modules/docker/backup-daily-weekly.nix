{ config, pkgs, vars, ... }:

let
  rsnapshotServicesConfDaily = pkgs.writeText "rsnapshot-services-daily.conf" ''
    config_version	1.2

    snapshot_root	${vars.dir.hoarder_data}/backup/

    retain	daily	4
    retain	weekly	6

    cmd_cp	${pkgs.coreutils}/bin/cp
    cmd_rm	${pkgs.coreutils}/bin/rm
    cmd_rsync	${pkgs.rsync}/bin/rsync
    cmd_logger	${pkgs.util-linux}/bin/logger
    cmd_du	${pkgs.coreutils}/bin/du

    rsync_short_args	-v
    rsync_long_args	--stats	-a	--delete
    loglevel	5
    backup	${vars.dir.scripts}/	scripts/
    backup	${vars.dir.certs}/	certs/
    backup	${vars.dir.nixos_config}/	nixos-config/
  '';

backupScriptServicesDaily = pkgs.writeShellScriptBin "backup-services-daily" ''
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

    if [ "$(date +%w)" -eq 0 ]; then
      echo "It's Sunday - Running rsnapshot weekly..."
      rsnapshot -v -c ${rsnapshotServicesConfDaily} weekly
    fi

    echo "Running rsnapshot daily..."
    rsnapshot -v -c ${rsnapshotServicesConfDaily} daily

    if [ -n "$DB_CONTAINERS" ]; then
      echo "Starting services: $(echo $DB_SERVICES)"
      systemctl start $DB_SERVICES
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
      ExecStart = "${backupScriptServicesDaily}/bin/backup-services-daily";
      StandardOutput = "journal+console";
      StandardError = "journal+console";
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
