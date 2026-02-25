{ pkgs, lib, ... }:

let
  check_playing = "${pkgs.playerctl}/bin/playerctl status 2>/dev/null | grep -q 'Playing'";
  
  brightnessctl = "${pkgs.brightnessctl}/bin/brightnessctl";
  hyprlock = "${pkgs.hyprlock}/bin/hyprlock";
  hyprctl = "${pkgs.hyprland}/bin/hyprctl";
in
{
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        # Avoid starting multiple hyprlock instances
        lock_cmd = "pidof ${hyprlock} || ${hyprlock}";
        # Lock before suspend
        before_sleep_cmd = "loginctl lock-session";
        # Turn on screen and restore brightness after waking up
        after_sleep_cmd = "${hyprctl} dispatch dpms on && ${brightnessctl} -r";
        
        # Respect media players
        ignore_dbus_inhibit = false;
      };

      listener = [
        # 1. DIM SCREEN & KBD (2.5 min)
        {
          timeout = 150;
          on-timeout = "${check_playing} || (${brightnessctl} -s set 10 && ${brightnessctl} -sd tpacpi::kbd_backlight set 0)";
          on-resume = "${brightnessctl} -r && ${brightnessctl} -rd tpacpi::kbd_backlight";
        }

        # 2. LOCK SESSION (5 min)
        {
          timeout = 300;
          on-timeout = "${check_playing} || loginctl lock-session";
        }

        # 3. DPMS OFF (5.5 min)
        {
          timeout = 330;
          on-timeout = "${check_playing} || ${hyprctl} dispatch dpms off";
          on-resume = "${hyprctl} dispatch dpms on";
        }

        # 4. SUSPEND (30 min)
        {
          timeout = 1800;
          on-timeout = "${check_playing} || systemctl suspend";
        }
      ];
    };
  };
}
