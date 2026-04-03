{ config, pkgs, inputs, vars, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./networking.nix
    ../../modules/common.nix
    ../../modules/shell.nix
    ../../modules/desktop/hyprland.nix
    ../../modules/sudo.nix
    ../../modules/docker/init_base.nix
    ../../modules/utilities.nix
    ../../modules/printing.nix
    ../../modules/virtual-machines/virt-manager.nix
    ./wireshark.nix
    ./mounts.nix
  ];


  # Boot configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Gnome keyring daemon for secrets management
  services.gnome.gnome-keyring.enable = true;

  hardware.bluetooth.enable = true;
  programs.kdeconnect.enable = true;

  environment.systemPackages = with pkgs; [
    ntfs3g
    dnsmasq
    sshfs
    wireguard-tools
  ];


  boot.kernelModules = [ "drivetemp" ];  # for reading HDD temps
  users.users.${vars.username}.extraGroups = [ "dialout" ]; # for flashing microcontrolers

  system.stateVersion = "25.11";
}
