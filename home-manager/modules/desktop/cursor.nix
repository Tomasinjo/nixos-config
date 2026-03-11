{ pkgs, ... }:

let
  cursorFlavor = "mochaDark"; # latte, frappe, macchiato, mocha, mochaDark
  cursorName = "catppuccin-mocha-dark-cursors"; 
in
{
  home.packages = [ 
    pkgs.catppuccin-cursors.${cursorFlavor} 
  ];

  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    package = pkgs.catppuccin-cursors.${cursorFlavor};
    name = cursorName;
    size = 24;
  };

  gtk = {
    enable = true;
    cursorTheme = {
      package = pkgs.catppuccin-cursors.${cursorFlavor};
      name = cursorName;
      size = 24;
    };
  };

  wayland.windowManager.hyprland.settings = {
    exec-once = [
      "hyprctl setcursor catppuccin-mocha-dark-cursors 24"
    ];
    env = [
      "HYPRCURSOR_THEME,${cursorName}"
      "HYPRCURSOR_SIZE,24"
      "XCURSOR_THEME,${cursorName}"
      "XCURSOR_SIZE,24"
    ];
  };
}