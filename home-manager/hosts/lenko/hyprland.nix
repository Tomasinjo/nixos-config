{ config, pkgs, ... }:

{
  wayland.hyprland = {
    settings = {
      monitor = [
        "desc:LG Electronics LG ULTRAWIDE 0x00037CB8, 2560x1080@75, 2560x0, 1"
        "eDP-1, 1920x1080@60, 0x1080, 1"
      ];
      
      exec-once = [
        "hypridle"
        "[workspace 6 silent] Telegram"
        "[workspace 6 silent] discord"
        "[workspace 5 silent] kitty yazi"
        "[workspace 5 silent] kitty"
        "kdeconnect-indicator"
        "[workspace 1 silent] firefox"
        "dbus-update-activation-environment --all"
        "gnome-keyring-daemon --start --components=secrets"
      ];

      bind = [
        ", PRINT, exec, hyprshot -m region -o ~/screenshots/"
        ", XF86MonBrightnessUp, exec, brightnessctl set 5%+"
        ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
        ", XF86AudioMicMute, exec, pamixer --default-source --toggle-mute"
        "$mainMod, plus, fullscreen"
      ];

      workspace = [
        "1, monitor:desc:LG Electronics LG ULTRAWIDE 0x01010101, default:true"
        "2, monitor:desc:LG Electronics LG ULTRAWIDE 0x01010101, default:true"
        "3, monitor:desc:LG Electronics LG ULTRAWIDE 0x01010101, default:true"
        "4, monitor:desc:LG Electronics LG ULTRAWIDE 0x00037CB8, default:true"
        "5, monitor:desc:LG Electronics LG ULTRAWIDE 0x00037CB8, default:true"
        "6, monitor:desc:LG Electronics LG ULTRAWIDE 0x00037CB8, default:true"
        "7, monitor:eDP-1, default:true"
        "8, monitor:eDP-1, default:true"
        "9, monitor:eDP-1, default:true"
      ];

      windowrule = [
        #"match:initial_class ^kitty$, match:initial_title ^kitty$, workspace 5"
        "workspace 6, match:class ^discord$"  # discord ignores exec-one workspace
        #"workspace 7, match:class ^org\.telegram\.desktop$"
      ];
      
      # overriding a base value instead of appending
      #general.gaps_in = 10; 
    };
  };
}
