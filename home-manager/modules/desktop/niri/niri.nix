{ config, lib, pkgs, ... }:

let
  inherit (lib) optionalString attrByPath;
in
{
  imports = [
    ./portals.nix
  ];

  config = {
    home.packages = with pkgs; [
      cliphist
      playerctl
      pavucontrol
      xwayland-satellite
      kalker
      catppuccin-cursors.mochaDark
    ];


    programs.niri = {
      settings = {
        spawn-at-startup = [
          { argv = [ "sh" "-c" "wl-paste --type text --watch cliphist store" ]; }
          { argv = [ "sh" "-c" "wl-paste --type image --watch cliphist store" ]; }
          { argv = [ "noctalia" ]; }
          { argv = [ "kdeconnect-indicator" ]; }
          { argv = [ "dbus-update-activation-environment" "--all" ]; }
          { argv = [ "gnome-keyring-daemon" "--start" "--components=secrets" ]; }
          { argv = [ "opencloud" ]; }
          { argv = [ "discord" ]; }
          { argv = [ "Telegram" ]; }
        ];

        "window-rules" = [
          {
            geometry-corner-radius.bottom-left = 8.0;
            geometry-corner-radius.bottom-right = 8.0;
            geometry-corner-radius.top-left = 8.0;
            geometry-corner-radius.top-right = 8.0;
            clip-to-geometry = true;
          }
          {
            matches = [ { app-id = "code"; } ];
            opacity = 0.93;
            draw-border-with-background = false;
            open-maximized = true;
          }
          {
            matches = [ { app-id = "discord"; } ];
            opacity = 0.87;
            draw-border-with-background = false;
            open-on-workspace = "chat";
          }
          {
            matches = [ { app-id = "^org\\.telegram\\.desktop$"; } ];
            opacity = 0.87;
            draw-border-with-background = false;
            open-on-workspace = "chat";
          }
          {
            matches = [ { app-id = "firefox"; } ];
            opacity = 0.94;
            draw-border-with-background = false;
            open-maximized = true;
          }
          {
            matches = [ { app-id = "kitty"; } ];
            opacity = 0.80;
            draw-border-with-background = false; # this is needed else opacity doesnt work
          }
          {
            matches = [ { app-id = "kalker"; } ];
            open-floating = true;
            default-window-height = { proportion = 0.4; };
            default-column-width = { proportion = 0.4; };
            opacity = 0.80;
            draw-border-with-background = false;
          }
          {
            matches = [ { app-id = "yazi"; } ];
            open-floating = true;
            default-window-height = { proportion = 0.7; };
            default-column-width = { proportion = 0.7; };
            opacity = 0.80;
            draw-border-with-background = false;
          }
        ];

        binds = {
          "Mod+Shift+Slash".action.show-hotkey-overlay = [ ];

          "Mod+T".action.spawn = [ "kitty" ];

          "XF86Calculator".action.spawn = [ "kitty" "--class" "kalker" "-e" "kalker" ];  # to set app-id to "kalker" so window rule matches

          "XF86AudioRaiseVolume".allow-when-locked = true;
          "XF86AudioRaiseVolume".action.spawn-sh = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%+";

          "XF86AudioLowerVolume".allow-when-locked = true;
          "XF86AudioLowerVolume".action.spawn-sh = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%-";

          "XF86AudioMute".allow-when-locked = true;
          "XF86AudioMute".action.spawn-sh = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";

          "XF86AudioMicMute".allow-when-locked = true;
          "XF86AudioMicMute".action.spawn-sh = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";

          "XF86AudioPlay".allow-when-locked = true;
          "XF86AudioPlay".action.spawn-sh = "playerctl play-pause";

          "XF86AudioPause".allow-when-locked = true;
          "XF86AudioPause".action.spawn-sh = "playerctl play-pause";

          "XF86AudioStop".allow-when-locked = true;
          "XF86AudioStop".action.spawn-sh = "playerctl stop";

          "XF86AudioPrev".allow-when-locked = true;
          "XF86AudioPrev".action.spawn-sh = "playerctl previous";

          "XF86AudioNext".allow-when-locked = true;
          "XF86AudioNext".action.spawn-sh = "playerctl next";

          "XF86MonBrightnessUp".allow-when-locked = true;
          "XF86MonBrightnessUp".action.spawn = [ "brightnessctl" "set" "5%+" ];

          "XF86MonBrightnessDown".allow-when-locked = true;
          "XF86MonBrightnessDown".action.spawn = [ "brightnessctl" "set" "5%-" ];

          "Mod+D".repeat = false;
          "Mod+D".action.toggle-overview = [ ];
          "Mod+Q".action.close-window = [ ];
          "Mod+L".action.spawn = [ "noctalia" "msg" "session" "lock" ];
          "Mod+R".action.spawn = [ "noctalia" "msg" "panel-open" "launcher" ];
          "Mod+E".action.spawn = [ "kitty" "--class" "yazi" "-e" "yazi" ];
          "Mod+V".action.spawn = [ "noctalia" "msg" "panel-open" "clipboard" ];
          "Print".action.screenshot = [ ];
          "Mod+Shift+S".action.screenshot = [ ];  # print screen on MX mechanical (F7)

          "Mod+F".action.maximize-column = [ ];
          "Mod+Shift+F".action.fullscreen-window = [ ];

          "Mod+C".action.center-column = [ ];
          "Mod+Ctrl+C".action.center-visible-columns = [ ];

          "Mod+Minus".action.set-column-width = "-10%";
          "Mod+Equal".action.set-column-width = "+10%";

          "Mod+A".action.toggle-window-floating = [ ];

          "Ctrl+Alt+Delete".action.quit = [ ];
          "Mod+Shift+P".action.power-off-monitors = [ ];

          # navigating windows horizontally on same workspace and vertically to different workspace
          "Mod+Left".action.focus-column-left = [ ];
          "Mod+Right".action.focus-column-right = [ ];
          "Mod+Down".action.focus-workspace-down = [ ];
          "Mod+Up".action.focus-workspace-up = [ ];

          # moving windows horizontally on same workspace and vertically to different workspace
          "Mod+Ctrl+Left".action.move-column-left = [ ];
          "Mod+Ctrl+Right".action.move-column-right = [ ];
          "Mod+Ctrl+Down".action.move-column-to-workspace-down = [ ];
          "Mod+Ctrl+Up".action.move-column-to-workspace-up = [ ];

          # jumping to first and last window
          "Mod+Home".action.focus-column-first = [ ];
          "Mod+End".action.focus-column-last = [ ];
          "Mod+Ctrl+Home".action.move-column-to-first = [ ];
          "Mod+Ctrl+End".action.move-column-to-last = [ ];

          # focus on monitor
          "Mod+Shift+Left".action.focus-monitor-left = [ ];
          "Mod+Shift+Down".action.focus-monitor-down = [ ];
          "Mod+Shift+Up".action.focus-monitor-up = [ ];
          "Mod+Shift+Right".action.focus-monitor-right = [ ];

          # moving windows to monitor
          "Mod+Shift+Ctrl+Left".action.move-column-to-monitor-left = [ ];
          "Mod+Shift+Ctrl+Down".action.move-column-to-monitor-down = [ ];
          "Mod+Shift+Ctrl+Up".action.move-column-to-monitor-up = [ ];
          "Mod+Shift+Ctrl+Right".action.move-column-to-monitor-right = [ ];


          "Mod+WheelScrollDown".cooldown-ms = 150;
          "Mod+WheelScrollDown".action.focus-workspace-down = [ ];

          "Mod+WheelScrollUp".cooldown-ms = 150;
          "Mod+WheelScrollUp".action.focus-workspace-up = [ ];

          "Mod+Ctrl+WheelScrollDown".cooldown-ms = 150;
          "Mod+Ctrl+WheelScrollDown".action.move-column-to-workspace-down = [ ];

          "Mod+Ctrl+WheelScrollUp".cooldown-ms = 150;
          "Mod+Ctrl+WheelScrollUp".action.move-column-to-workspace-up = [ ];

          "Mod+WheelScrollRight".action.focus-column-right = [ ];
          "Mod+WheelScrollLeft".action.focus-column-left = [ ];
          "Mod+Ctrl+WheelScrollRight".action.move-column-right = [ ];
          "Mod+Ctrl+WheelScrollLeft".action.move-column-left = [ ];

          "Mod+Shift+WheelScrollDown".action.focus-column-right = [ ];
          "Mod+Shift+WheelScrollUp".action.focus-column-left = [ ];
          "Mod+Ctrl+Shift+WheelScrollDown".action.move-column-right = [ ];
          "Mod+Ctrl+Shift+WheelScrollUp".action.move-column-left = [ ];

          "Mod+1".action.focus-workspace = 1;
          "Mod+2".action.focus-workspace = 2;
          "Mod+3".action.focus-workspace = 3;
          "Mod+4".action.focus-workspace = 4;
          "Mod+5".action.focus-workspace = 5;
          "Mod+6".action.focus-workspace = 6;
          "Mod+7".action.focus-workspace = 7;
          "Mod+8".action.focus-workspace = 8;
          "Mod+9".action.focus-workspace = 9;

          "Mod+Ctrl+1".action.move-column-to-workspace = 1;
          "Mod+Ctrl+2".action.move-column-to-workspace = 2;
          "Mod+Ctrl+3".action.move-column-to-workspace = 3;
          "Mod+Ctrl+4".action.move-column-to-workspace = 4;
          "Mod+Ctrl+5".action.move-column-to-workspace = 5;
          "Mod+Ctrl+6".action.move-column-to-workspace = 6;
          "Mod+Ctrl+7".action.move-column-to-workspace = 7;
          "Mod+Ctrl+8".action.move-column-to-workspace = 8;
          "Mod+Ctrl+9".action.move-column-to-workspace = 9;
        };

        # this and window-rule draw-border-with-background = false is needed for opacity to work when focus-ring is enabled
        prefer-no-csd = true;

        input = {
          keyboard = {
            xkb = {
              layout = "us,si";
              model = "";
              options = "grp:win_space_toggle";
              rules = "";
              variant = "";
            };
            numlock = true;
          };

          touchpad = {
            tap = true;
            natural-scroll = false;
          };

          mouse = {
            enable = true;
          };

          trackpoint = {
            enable = true;
          };
        };

        layout = {
          gaps = 16;

          center-focused-column = "never";

          preset-column-widths = [
            { proportion = 0.33333; }
            { proportion = 0.5; }
            { proportion = 0.66667; }
          ];

          default-column-width = { proportion = 0.5; };

          focus-ring = {
            enable = true;
            width = 2;
            active = {
              gradient = {
                "from" = "#33ccffee"; 
                "to" = "#00ff99ee"; 
                "angle" = 45;
              };
            };
            inactive = { color = "#505050"; };
          };

          border = {
            enable = false;
            width = 4;
            active = { color = "#ffc87f"; };
            inactive = { color = "#505050"; };
            urgent = { color = "#9b0000"; };
          };

          shadow = {
            enable = false;
            softness = 30;
            spread = 5;
            offset = { x = 0; y = 5; };
            color = "#0007";
          };
        };

        workspaces = {
          # order matters!
          "00-empty" = {};
          "01-chat" = {
            open-on-output = "eDP-1";
            name = "chat";
          };
        };

        screenshot-path = "~/screenshots/%Y-%m-%d %H-%M-%S.png";

        cursor = {
          theme = "catppuccin-mocha-dark-cursors";
          size = 24;
        };

        outputs = {
          "LG Electronics LG ULTRAWIDE 0x01010101" = {
            mode = {
              width = 2560;
              height = 1080;
              refresh = 75.0;
            };
            position = { x = 0; y = 0; };
            scale = 1.0;
          };
          "LG Electronics LG ULTRAWIDE 0x00037CB8" = {
            mode = {
              width = 2560;
              height = 1080;
              refresh = 75.0;
            };
            position = { x = 2560; y = 0; };
            scale = 1.0;
          };
          "eDP-1" = {
            mode = {
              width = 1920;
              height = 1200;
              refresh = 60.0;
            };
            position = { x = 0; y = 1080; };
            scale = 1.0;
          };
        };
      };
    };
  };
}
