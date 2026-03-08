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
# sudo backup-important-quarterly

let
  rsnapshotImportantConf = pkgs.writeText "rsnapshot-quarterly-important.conf" ''
    config_version	1.2

    snapshot_root	/home/tom/mnt/important-data

    retain	quarterly	4
    interval	quarterly	1

    cmd_rsync	${pkgs.rsync}/bin/rsync
    rsync_long_args	--archive --delete --numeric-ids

    backup	/impo-data/	important-data/
  '';

  backupScriptImportant = pkgs.writeShellScriptBin "backup-important-quarterly" ''
    PATH=$PATH:${pkgs.docker}/bin:${pkgs.rsnapshot}/bin:${pkgs.rsync}/bin:${pkgs.coreutils}/bin:${pkgs.gnugrep}/bin
    
    echo "Running data rsnapshot quarterly..."
    rsnapshot -c ${rsnapshotImportantConf} quarterly
    
    echo "Backup and restart completed."
  '';
in
{
  environment.systemPackages = [ 
    backupScriptImportant  # This makes the 'backup-important-quarterly' command available in terminal
  ];
}
