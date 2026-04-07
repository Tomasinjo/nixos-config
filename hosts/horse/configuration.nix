{ config, pkgs, inputs, vars, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./networking.nix
    ../../modules/common.nix
    ../../modules/shell.nix
    ../../modules/desktop/hyprland.nix
    ../../modules/sudo.nix
    ../../modules/utilities.nix
    ../../modules/wireshark.nix
    ../../modules/ssh.nix
    ../../modules/intune.nix
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
    wireguard-tools
    foot
    xfce.xfce4-terminal
    gnome-keyring
    libsecret 
  ];

  system.stateVersion = "25.11";


  hardware.graphics = {
    enable = true;
  };
  services.xserver.videoDrivers = [ "vmware" ];
  virtualisation.vmware.guest.enable = true;
  services.intune.enable = true;

  # VMWARE
  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    WLR_RENDERER_ALLOW_SOFTWARE = "1";
    LIBGL_ALWAYS_SOFTWARE = "1";
  };
}
