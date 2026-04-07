{ config, pkgs, inputs, ... }:
{
  imports = [
    ./waybar.nix
  ];

  wayland.hyprland = {
    settings = {
    # Zenki specific Hyprland settings
  monitor = [
    ",preferred,auto,1"
  ];

  # You can also add those environment variables here for VirtualBox
  env = [
    "WLR_NO_HARDWARE_CURSORS,1"
    "WLR_RENDERER_ALLOW_SOFTWARE,1"
    "GDK_BACKEND,wayland,x11,*"
    "QT_QPA_PLATFORM,wayland;xcb"
    "SDL_VIDEODRIVER,wayland"
    "CLUTTER_BACKEND,wayland"

  ];
  exec-once = [
    # 1. Update the D-Bus activation environment so the Broker can see the Keyring
     "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"

# 2. Specifically start the gnome-keyring-daemon with the 'secrets' component
     "gnome-keyring-daemon --start --components=secrets"
  ];
  };
  };
}

