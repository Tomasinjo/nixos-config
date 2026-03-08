{ config, pkgs, ... }:

{
  # Sanoid (Snapshot Management)
  # handles snapshot creation on source and pruning (rotation) on both source and target
  services.sanoid = {
    enable = true;
    interval = "hourly"; # Sanoid timer runs frequently, but templates decide action

    templates = {  
      production = {  # source side where snapshots are created and later transfered with syncoid to target
        hourly = 0;
        daily = 30;
        monthly = 6;
        yearly = 0;
        autosnap = true;
        autoprune = true;
      };
      backup = {  # target side where backups are stored. Only pruning, no new snapshots.
        hourly = 0;
        daily = 30; 
        monthly = 6;
        yearly = 0;
        autosnap = false;  # only prune here, not take new snapshots.
        autoprune = true;
      };
    };

    datasets = {
      "impo-data" = {
        useTemplate = [ "production" ];
        recursive = true;
      };
      "hoarder-data/backups-impo-data" = {
        useTemplate = [ "backup" ];
        recursive = true;
      };
    };
  };

  # Syncoid (Replication)
  # sends incremental snapshots from source to target
  systemd.services.syncoid-backup = {
    description = "Replicate ZFS snapshots from impo-data to hoarder-data";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.sanoid}/bin/syncoid -r impo-data hoarder-data/backups-impo-data";
      User = "root";
    };
  };

  systemd.timers.syncoid-backup = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 04:05:00";
      Persistent = true;
      RandomizedDelaySec = "5m";
    };
  };
  
  environment.systemPackages = [ pkgs.sanoid ];
}