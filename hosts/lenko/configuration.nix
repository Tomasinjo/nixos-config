{ config, pkgs, inputs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./networking.nix
    ../../modules/common.nix
    ../../modules/desktop.nix
    ../../modules/sudo.nix
    ../../modules/docker.nix
    ../../modules/utilities.nix
    ../../modules/piper.nix
    ./mounts.nix
  ];

  networking.hostName = "lenko";

  # Boot configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.useOSProber = true;
  # Gnome keyring daemon for secrets management
  services.gnome.gnome-keyring.enable = true;

  hardware.bluetooth.enable = true;
  
  programs.kdeconnect.enable = true;

  environment.systemPackages = with pkgs; [
    hypridle
    ntfs3g
    dnsmasq
    sshfs
  ];

  system.activationScripts.screenshotsDir = ''
    mkdir -p /home/tom/screenshots
    chown tom:users /home/tom/screenshots
  '';

  nixpkgs.config.permittedInsecurePackages = [
    "qtwebengine-5.15.19"   # for openshot
  ];

  system.stateVersion = "25.11";
}
