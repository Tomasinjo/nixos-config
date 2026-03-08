{ pkgs, ... }:

{
  boot.supportedFilesystems = [ "zfs" ];
  
  boot.zfs.extraPools = [ "hoarder-data" "impo-data" ]; # import on boot

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