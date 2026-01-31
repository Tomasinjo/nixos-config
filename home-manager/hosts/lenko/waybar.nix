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
        align = 0;
        justify = "left";
        format = "{}";
        interval = 1;
        exec = "~/.config/waybar/scripts/powerdraw.sh";
        return-type = "json";
      };

      bluetooth = {
        align = 0;
        justify = "left";
        controller = "controller1";
        format = " {status}  ";
        format-disabled = "";
        format-connected = " {num_connections}";
        tooltip-format = "{controller_alias}\t{controller_address}";
        tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{device_enumerate}";
        tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
        on-click = "rofi-bluetooth";
      };

      network = {
        align = 0;
        justify = "left";
        format = "{ifname}";
        format-wifi = "  {signalStrength}%";
        format-ethernet = " ";
        format-disconnected = "";
        tooltip-format = "{ifname} via {gwaddr} 󰊗";
        tooltip-format-wifi = "{essid} - {ipaddr}/{cidr}";
        tooltip-format-ethernet = "{ipaddr}/{cidr}";
        tooltip-format-disconnected = "Disconnected";
        max-length = 50;
        on-click = "networkmanager_dmenu";
      };

      battery = {
        align = 0;
        justify = "left";
        interval = 1;
        states = {
          good = 95;
          warning = 30;
          critical = 20;
        };
        format = "{icon} {capacity}%";
        format-charging = "󰂄 {capacity}%";
        format-plugged = "󰂄 {capacity}%";
        format-alt = "{icon} {time}";
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
        align = 0;
        justify = "left";
        device = "amdgpu_bl1";
        format = "{icon} {percent}%";
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
