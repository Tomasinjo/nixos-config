{ pkgs, ... }:

{
  home.packages = [ pkgs.papirus-icon-theme ];

  programs.rofi = {
    enable = true;
    package = pkgs.rofi;
    plugins = [
      pkgs.rofi-calc
    ];
    theme = "material";
    extraConfig = {
      show-icons = true;
      icon-theme = "Papirus";
    };
  };

  xdg.desktopEntries = {
    "rofi-calc" = {
      name = "Calculator";
      exec = "rofi -show calc -modi calc -no-show-match -no-sort";
      icon = "accessories-calculator";
      comment = "Scientific Calculator";
      categories = [ "Utility" "Calculator" ];
    };
  };
}
