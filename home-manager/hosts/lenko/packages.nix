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
    libreoffice-still
    vlc
    imv
    imagemagick
    rofi-bluetooth
    networkmanager_dmenu
    realvnc-vnc-viewer
    nextcloud-client
    arduino-ide
    protonmail-desktop
  ];
}
