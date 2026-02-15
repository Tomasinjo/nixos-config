{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    less
    usbutils
    tcpdump
    netcat
    git-crypt # secrets encryption for nixos config
    openssl
    smartmontools  # smartctl
    screen
  ];
}
