{ config, pkgs, ... }:

{
  programs.discord.enable = true;
  home.packages = with pkgs; [
  ];
}
