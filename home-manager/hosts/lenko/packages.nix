{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    hyprshot
    pamixer
    telegram-desktop
    esptool
    zoom-us
    filezilla
    gimp
    pkgs.onlyoffice-desktopeditors
    vlc
    imv
    imagemagick
    rofi-bluetooth
    networkmanager_dmenu
    realvnc-vnc-viewer
    nextcloud-client
    arduino-ide
    protonmail-desktop
    kdePackages.okular # pdf reader. To import sigen certs use nix-shell -p nssTools.tools, pk12util -d sql:$HOME/.pki/nssdb -i Downloads/sigen-ca.p12
  ];
}
