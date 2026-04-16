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
    ../../modules/wireshark.nix
  ];


  # Boot configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Gnome keyring daemon for secrets management
  services.gnome.gnome-keyring.enable = true;

  services.fprintd.enable = true;  # add fingers with fprintd-enroll

  hardware.bluetooth.enable = true;
  programs.kdeconnect.enable = true;

  environment.systemPackages = with pkgs; [
    ntfs3g
    dnsmasq
    wireguard-tools
    direnv # for python projects so vscode recognizes nix shell
    nix-direnv 
  ];


  boot.kernelModules = [ "drivetemp" ];  # for reading HDD temps
  users.users.${vars.username}.extraGroups = [ "dialout" ]; # for flashing microcontrolers

  system.stateVersion = "25.11";
}
