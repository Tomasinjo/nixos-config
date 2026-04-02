{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    rofi-bluetooth
    networkmanager_dmenu
  ];
}
