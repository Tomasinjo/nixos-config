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
          position = "left";
          modules-left = cfg.modulesLeft;
          modules-center = cfg.modulesCenter;
          modules-right = cfg.modulesRight;
          reload_style_on_change = true;

          "hyprland/workspaces" = {
            format = "{name}";
            on-click = "activate";
            sort-by-number = true;
          };

          clock = {
            format = "{:%d.%m.\n%H:%M}";
            interval = 1;
            tooltip-format = "<small>{:%H:%M:%S}</small>\n<tt><small>{calendar}</small></tt>";
            calendar-weeks-pos = "right";
            today-format = "<span color='#7645AD'><b><u>{}</u></b></span>";
            format-calendar = "<span color='#aeaeae'><b>{}</b></span>";
            format-calendar-weeks = "<span color='#aeaeae'><b>W{:%V}</b></span>";
            format-calendar-weekdays = "<span color='#aeaeae'><b>{}</b></span>";
          };

          disk = {
            interval = 300;
            format = "󰋊 {percentage_used}%";
            path = "/";
            align = 0;
            justify = "left";
          };

          cpu = {
            align = 0;
            justify = "left";
            format-critical = "<span color='#c20821'><b>󰻠 {usage}%</b></span>";
            format-high = "<span color='#bb5613'>󰻠 {usage}%</span>";
            format-medium = "<span color='#a58315'>󰻠 {usage}%</span>";
            format-low = "<span color='#6b9fa8'>󰻠 {usage}%</span>";
            interval = 3;
            states = {
              critical = 80;
              high = 50;
              medium = 10;
              low = 0;
            };
            on-click = "kitty btop";
          };

          memory = {
            align = 0;
            justify = "left";
            format-critical = "<span color='#c20821'><b>󰍛 {percentage}%</b></span>";
            format-high = "<span color='#bb5613'>󰍛 {percentage}%</span>";
            format-medium = "<span color='#a58315'>󰍛 {percentage}%</span>";
            format-low = "<span color='#6b9fa8'>󰍛 {percentage}%</span>";
            interval = 5;
            states = {
              critical = 80;
              high = 60;
              medium = 30;
              low = 0;
            };
          };

          temperature = {
            align = 0;
            justify = "left";
            format = " {temperatureC}°C";
            format-critical = " {temperatureC}°C";
            interval = 5;
            critical-threshold = 65;
          };

          pulseaudio = {
            align = 0;
            justify = "left";
            format = "{icon}  {volume}%";
            format-bluetooth = "{icon}  {volume}%";
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
            align = 0;
            justify = "left";
            format = "{} 󱎔";
            format-xrun = "{xruns} xruns";
            format-disconnected = "DSP off";
            realtime = true;
          };
        } // cfg.extraModules // cfg.extraSettings );
      };

      style = ''
        * {
            border: none;
            font-size: 14px;
            font-family: "JetBrainsMono Nerd Font,JetBrainsMono NF" ;
            min-width: 38px;
        }

        window#waybar {
          background: transparent;
         }

        #custom-logo {
          padding: 10px 0;
          color: #5ea1ff;
        }

        .modules-right {
          padding-top: 5px;
          border-radius: 15px 15px 0 0;
          background: #000000;
        }

        .modules-center {
          padding: 15px 0;
          border-radius: 15px 15px 15px 15px;
          background: #000000;
        }

        .modules-left {
          border-radius: 0 0 15px 15px;
          background: #000000;
        }

        #battery,
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
        #workspaces {
          padding: 5px 0;
          color: #6b9fa8
        }
        #workspaces button {
        	margin-left: 0px;
        	margin-right: 5px;

        	padding-left: 10px;
        	padding-right: 5px;
        }

        #workspaces button:hover {
        	background-color: rgba(147, 154, 183, 0.2);
        }

        #workspaces button.empty {
        	border: 0px;

        	padding-right: 0px;
        }

        #workspaces button.visible {
        	background-color: rgba(54, 58, 79, 0.9);

        	border: 2px solid @overlay0;

        	color: @blue;
        }

        #clock {
          padding: 5px 0;
          color: #758686;
        }

        #pulseaudio {
          padding-left: 3px;
        }

        #temperature.critical,
        #pulseaudio.muted {
          color: #c20821;
          padding-top: 0;
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
      #!${pkgs.bash}/bin/bash

      if [ -f /sys/class/power_supply/BAT*/power_now ]; then
        powerDraw=" $(($(cat /sys/class/power_supply/BAT*/power_now)/1000000)) W"
      fi


      cat << EOF
      { "text":"$powerDraw", "tooltip":"power Draw $powerDraw" }
      EOF
    '';

    xdg.configFile."waybar/scripts/powerdraw.sh".executable = true;
  };
}
