{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    wget
    curl
    btop
    tree
    pciutils
    p7zip
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
