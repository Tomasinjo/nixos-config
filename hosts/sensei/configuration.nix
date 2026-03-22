{ config, pkgs, inputs, vars, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./networking.nix
    ./kea.nix
    ./nftables.nix
    ./unbound.nix
    ./wireguard.nix
    
    ../../modules/common.nix
    ../../modules/shell.nix
    ../../modules/sudo.nix
    ../../modules/ssh.nix
    ../../modules/utilities.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  environment.systemPackages = with pkgs; [
    ethtool
    tcpdump
    iftop
    iperf3
    wireguard-tools
    conntrack-tools
    nftables
  ];

  # NTP server and client
  services.chrony = {
    enable = true;
    extraConfig = ''
      bindaddress ${vars.net.sensei.ipv4DNS}
      bindaddress ${vars.net.sensei.ipv6DNS}

      allow 192.168.0.0/16
      allow ${vars.net.sensei.ipv6_prefix}
      allow fe80::/10

      pool pool.ntp.org iburst
    '';
  };

  users.users.${vars.username}.extraGroups = [ "networkmanager" ];

  system.stateVersion = "25.11";
}
