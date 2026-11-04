{ pkgs, ... }:

{
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.extraPools = [ "hoarder-data" "impo-data" ]; # import on boot
  boot.zfs.forceImportRoot = false; # reduces risk of data loss in rare events, recommended for release 26.11

  services.zfs.autoScrub.enable = true;
  services.zfs.autoScrub.interval = "Weekly";

  environment.systemPackages = with pkgs; [
    rsync
  ];

  imports = [
    ./backup-daily.nix
    ./backup-quarterly.nix
  ];
}
