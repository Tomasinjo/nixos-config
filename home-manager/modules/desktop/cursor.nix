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
    exec_cmd = [
      "hyprctl setcursor catppuccin-mocha-dark-cursors 24"
    ];
    env = [
      {_args = ["HYPRCURSOR_THEME" "${cursorName}"];}
      {_args = ["HYPRCURSOR_SIZE" "24"];}
      {_args = ["XCURSOR_THEME" "${cursorName}"];}
      {_args = ["XCURSOR_SIZE" "24"];}
    ];
  };
}
