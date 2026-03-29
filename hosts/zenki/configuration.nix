{ config, pkgs, inputs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./networking.nix
    ../../modules/shell.nix
    ../../modules/common.nix
    ../../modules/docker/init.nix
    ../../modules/ssh.nix
    ../../modules/zfs/init.nix
    ../../modules/desktop.nix
    ../../modules/gaming.nix
    ../../modules/utilities.nix
    ../../modules/sudo.nix
    ../../modules/virtual-machines/libvirt.nix

    ../../modules/hardware/intel/intel-qsv.nix
    ../../modules/hardware/intel/efficiency.nix
    ../../modules/hardware/nvidia/init.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

<<<<<<< HEAD
=======
  programs.nix-ld.enable = true; # allow unsigned links, requred for connecting with vscode remote ssh

>>>>>>> d77319e9b9a8b8dc87a973320b35076d0602b5dc
  system.stateVersion = "25.11";
}
