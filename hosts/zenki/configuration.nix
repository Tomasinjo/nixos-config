{ config, pkgs, inputs, vars, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./networking.nix
    ../../modules/common.nix
    ../../modules/podman/init.nix
    ../../modules/vector.nix
    ../../modules/cowabunga/syslog-sender.nix
    ../../modules/ssh.nix
    ../../modules/zfs/init.nix
    ../../modules/desktop/hyprland.nix
    ../../modules/utilities.nix
    ../../modules/sudo.nix
    ../../modules/virtual-machines/libvirt.nix

    ../../modules/hardware/intel/intel-qsv.nix
    ../../modules/hardware/intel/efficiency.nix
    ../../modules/hardware/nvidia/init.nix

    ../../modules/gaming/gamemode.nix
    ../../modules/gaming/steam.nix
    # ../../modules/gaming/sunshine.nix
    ../../modules/wireshark.nix  # for dumpcap, remote capture via wireshark

  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  modules.vector = {
    enable = true;
    enablePodman = true;
    extraFiles = [
      "${vars.dir.nixos_config}/apps/ha/appdaemon/app-data/logs/appdaemon.log"
      "${vars.dir.nixos_config}/apps/ha/appdaemon/app-data/logs/error.log"
    ];
  };

  programs.nix-ld.enable = true; # allow unsigned links, requred for connecting with vscode remote ssh

  system.stateVersion = "25.11";
}
