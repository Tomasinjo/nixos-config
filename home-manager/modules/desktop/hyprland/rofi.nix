{ pkgs, ... }:

{
  home.packages = [ pkgs.papirus-icon-theme ];

  programs.rofi = {
    enable = true;
    package = pkgs.rofi;
    theme = "material";
    extraConfig = {
      show-icons = true;
      icon-theme = "Papirus";
    };
  };
}