{ config, pkgs, inputs, vars, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./networking.nix
    ../../modules/common.nix
    ../../modules/desktop/niri.nix
    ../../modules/sudo.nix
    ../../modules/docker/init.nix
    ../../modules/utilities.nix
    ../../modules/wireshark.nix
    ../../modules/hardware/upower.nix
  ];

  # Gnome keyring daemon for secrets management
  services.gnome.gnome-keyring.enable = true;


  environment.systemPackages = with pkgs; [
    dnsmasq
    wireguard-tools
    direnv # for python projects so vscode recognizes nix shell
    nix-direnv
  ];

  system.stateVersion = "25.11";
}
