{ config, pkgs, ... }:
{
  wayland.waybar = {
    modulesLeft = [ "custom/logo" "clock" "cpu" "memory" "disk" "temperature" "custom/powerDraw" ];
    modulesCenter = [ "hyprland/workspaces" ];
    modulesRight = [ "backlight" "bluetooth" "pulseaudio" "network" "battery" ];

    extraModules = {
      "custom/logo" = {
        format = "";
        tooltip = false;
        on-click = "kitty -e --hold fastfetch";
      };

      "custom/powerDraw" = {
        format = "{}";
        interval = 1;
        exec = "~/.config/waybar/scripts/powerdraw.sh";
        return-type = "json";
      };

      "custom/clipboard" = {
        format = "";
        on-click = "cliphist list | rofi -dmenu | cliphist decode | wl-copy";
        interval = 86400;
      };

      bluetooth = {
        controller = "controller1";
        format = " {status}  ";
        format-disabled = "";
        format-connected = " {num_connections} connected";
        tooltip-format = "{controller_alias}\t{controller_address}";
        tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{device_enumerate}";
        tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
        on-click = "rofi-bluetooth";
      };

      network = {
        format = "{ifname}";
        format-wifi = "{essid} ({signalStrength}%)   ";
        format-ethernet = " ";
        format-disconnected = "";
        tooltip-format = "{ifname} via {gwaddr} 󰊗";
        tooltip-format-wifi = "{ipaddr}/{cidr}";
        tooltip-format-ethernet = "{ipaddr}/{cidr}";
        tooltip-format-disconnected = "Disconnected";
        max-length = 50;
        on-click = "networkmanager_dmenu";
      };

      battery = {
        interval = 1;
        states = {
          good = 95;
          warning = 30;
          critical = 20;
        };
        format = "{capacity}%  {icon} ";
        format-charging = "{capacity}% 󰂄 ";
        format-plugged = "{capacity}% 󰂄 ";
        format-alt = "{time} {icon}";
        format-icons = [
          "󰁻"
          "󰁼"
          "󰁾"
          "󰂀"
          "󰂂"
          "󰁹"
        ];
      };

      backlight = {
        device = "amdgpu_bl1";
        format = "{percent}% {icon}   ";
        format-icons = [ "" "" ];
        on-scroll-up = "brightnessctl -q s 5%+";
        on-scroll-down = "brightnessctl -q s 5%-";
      };
    };
  };

  home.packages = with pkgs; [
    brightnessctl
  ];
}
