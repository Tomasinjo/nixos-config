{ config, pkgs, inputs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./networking.nix
    ../../modules/common.nix
    ../../modules/nvidia.nix
    ../../modules/docker.nix
    ../../modules/ssh.nix
    ../../modules/intel-qsv.nix
    ../../modules/backup-zfs.nix
    ../../modules/backup-docker.nix
    ../../modules/backup-quarterly.nix
    ../../modules/desktop.nix
    ../../modules/gaming.nix
#    ../../modules/cockpit.nix
    ../../modules/utilities.nix
    ../../modules/sudo.nix
    ../../modules/vector.nix
    ../../modules/nvidia-fan-control.nix
    ../../modules/efficiency.nix
  ];

  networking.hostId = "a8c00f0a";
  networking.hostName = "zenki";
  boot.supportedFilesystems = [ "zfs" ];
  
  boot.zfs.extraPools = [ "hoarder-data" "impo-data" ]; # import on boot

  services.zfs.autoScrub.enable = true;
  services.zfs.autoScrub.interval = "Weekly";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  system.stateVersion = "25.11";
}
