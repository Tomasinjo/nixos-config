{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.wayland.waybar;
in
{
  options.wayland.waybar = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Waybar status bar";
    };
    modulesLeft = mkOption {
      type = types.listOf types.str;
      default = [ "clock" "cpu" "memory" "temperature" ];
      description = "Modules to display on the left side";
    };
    modulesCenter = mkOption {
      type = types.listOf types.str;
      default = [ "hyprland/workspaces" ];
      description = "Modules to display in the center";
    };
    modulesRight = mkOption {
      type = types.listOf types.str;
      default = [ "pulseaudio" ];
      description = "Modules to display on the right side";
    };
    extraModules = mkOption {
      type = types.attrs;
      default = { };
      description = "Additional module configurations";
    };
    extraSettings = mkOption {
      type = types.attrs;
      default = { };
      description = "Additional waybar settings";
    };
  };

  config = mkIf cfg.enable {
    programs.waybar = {
      enable = true;
      settings = {
        main = ({
          layer = "top";
          position = "top";
          modules-left = cfg.modulesLeft;
          modules-center = cfg.modulesCenter;
          modules-right = cfg.modulesRight;
          reload_style_on_change = true;

          "hyprland/workspaces" = {
            format = "{icon}";
            on-click = "activate";
            format-icons = {
              active = "";
              default = "";
            };
            sort-by-number = true;
            persistent-workspaces = {
              "*" = [ 1 2 3 4 5 6 ];
            };
          };

          clock = {
            format = "{:%Y-%m-%d %H:%M:%S}";
            interval = 1;
            tooltip-format = "\n<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
            calendar-weeks-pos = "right";
            today-format = "<span color='#7645AD'><b><u>{}</u></b></span>";
            format-calendar = "<span color='#aeaeae'><b>{}</b></span>";
            format-calendar-weeks = "<span color='#aeaeae'><b>W{:%V}</b></span>";
            format-calendar-weekdays = "<span color='#aeaeae'><b>{}</b></span>";
          };

          disk = {
            interval = 300;
            format = "DISK: {percentage_used}%   ";
            path = "/";
          };

          cpu = {
            format-critical = "<span color='#c20821'><b>CPU: {usage}%</b></span>";
            format-high = "<span color='#bb5613'>CPU: {usage}%</span>";
            format-medium = "<span color='#a58315'>CPU: {usage}%</span>";
            format-low = "<span color='#6b9fa8'>CPU: {usage}%</span>";
            interval = 3;
            states = {
              critical = 80;
              high = 50;
              medium = 10;
              low = 0;
            };
            on-click = "kitty htop";
          };

          memory = {
            format-critical = "<span color='#c20821'><b>MEM: {percentage}%</b></span>";
            format-high = "<span color='#bb5613'>MEM: {percentage}%</span>";
            format-medium = "<span color='#a58315'>MEM: {percentage}%</span>";
            format-low = "<span color='#6b9fa8'>MEM: {percentage}%</span>";
            interval = 5;
            states = {
              critical = 80;
              high = 60;
              medium = 30;
              low = 0;
            };
          };

          temperature = {
            format = " {temperatureC}°C";
            format-critical = " {temperatureC}°C";
            interval = 5;
            critical-threshold = 65;
          };

          pulseaudio = {
            format = "{volume}% {icon}  ";
            format-bluetooth = "{volume}% {icon}  ";
            format-muted = "";
            format-icons = {
              "alsa_output.pci-0000_00_1f.3.analog-stereo" = "";
              "alsa_output.pci-0000_00_1f.3.analog-stereo-muted" = "";
              headphone = "";
              "hands-free" = "";
              headset = "";
              phone = "";
              "phone-muted" = "";
              portable = "";
              car = "";
              default = [ "" "" ];
            };
            scroll-step = 1;
            on-click = "pavucontrol";
            ignored-sinks = [ "Easy Effects Sink" ];
          };

          jack = {
            format = "{} 󱎔";
            format-xrun = "{xruns} xruns";
            format-disconnected = "DSP off";
            realtime = true;
          };

          upower = {
            show-icon = false;
            hide-if-empty = true;
            tooltip = true;
            tooltip-spacing = 20;
          };
        } // cfg.extraModules // cfg.extraSettings );
      };

      style = ''
        * {
            border: none;
            font-size: 14px;
            font-family: "JetBrainsMono Nerd Font,JetBrainsMono NF" ;
            min-height: 25px;
        }

        window#waybar {
          background: transparent;
          margin: 5px;
         }

        #custom-logo {
          padding: 0 10px;
          color: #5ea1ff;
        }

        .modules-right {
          padding-left: 5px;
          border-radius: 15px 0 0 15px;
          margin-top: 2px;
          background: #000000;
        }

        .modules-center {
          padding: 0 15px;
          margin-top: 2px;
          border-radius: 15px 15px 15px 15px;
          background: #000000;
        }

        .modules-left {
          border-radius: 0 15px 15px 0;
          margin-top: 2px;
          background: #000000;
        }

        #battery,
        #custom-clipboard,
        #custom-colorpicker,
        #custom-powerDraw,
        #bluetooth,
        #pulseaudio,
        #network,
        #disk,
        #memory,
        #backlight,
        #cpu,
        #temperature,
        #custom-weather,
        #idle_inhibitor,
        #jack,
        #tray,
        #window,
        #workspaces,
        #clock {
          padding: 0 5px;
          color: #6b9fa8
        }
        #pulseaudio {
          padding-top: 3px;
        }

        #temperature.critical,
        #pulseaudio.muted {
          color: #c20821;
          padding-top: 0;
        }

        #clock{
          color: #758686;
        }

        #battery.charging {
            color: #ffffff;
            background-color: #26A65B;
        }

        #battery.warning:not(.charging) {
            background-color: #ffbe61;
            color: black;
        }

        #battery.critical:not(.charging) {
            background-color: #f53c3c;
            color: #ffffff;
            animation-name: blink;
            animation-duration: 0.5s;
            animation-timing-function: linear;
            animation-iteration-count: infinite;
            animation-direction: alternate;
        }


        @keyframes blink {
            to {
                background-color: #ffffff;
                color: #000000;
            }
        }
      '';
    };

    home.packages = with pkgs; [
      pavucontrol
    ];

    xdg.configFile."waybar/scripts/powerdraw.sh".text = ''
      #!/bin/bash

      if [ -f /sys/class/power_supply/BAT*/power_now ]; then
        powerDraw="  $(($(cat /sys/class/power_supply/BAT*/power_now)/1000000))w"
      fi


      cat << EOF
      { "text":"$powerDraw", "tooltip":"power Draw $powerDraw"}
      EOF
    '';

    xdg.configFile."waybar/scripts/powerdraw.sh".executable = true;
  };
}
