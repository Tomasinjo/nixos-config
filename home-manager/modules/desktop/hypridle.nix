{ pkgs, lib, ... }:

let
  brightnessctl = "${pkgs.brightnessctl}/bin/brightnessctl";
  hyprlock = "${pkgs.hyprlock}/bin/hyprlock";
  hyprctl = "${pkgs.hyprland}/bin/hyprctl";
  playerctl = "${pkgs.playerctl}/bin/playerctl";

  checkPlayingAndRun = cmd: "${playerctl} status 2>/dev/null | grep -q \"Playing\" || ${cmd}";
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
        after_sleep_cmd = "${hyprctl} dispatch \"dpms on\" && ${brightnessctl} -r";
        
        # Respect media players
        ignore_dbus_inhibit = false;
      };

      listener = [
        # 1. DIM SCREEN & KBD
        {
          timeout = 150;
          on-timeout = checkPlayingAndRun "${brightnessctl} -s set 10 && ${brightnessctl} -sd tpacpi::kbd_backlight set 0";
          on-resume = "${brightnessctl} -r && ${brightnessctl} -rd tpacpi::kbd_backlight";
        }

        # 2. LOCK SESSION
        {
          timeout = 210;
          on-timeout = checkPlayingAndRun "loginctl lock-session";
        }

        # 3. Screen OFF
        {
          timeout = 300;
          on-timeout = checkPlayingAndRun "${hyprctl} eval 'hl.dispatch(hl.dsp.dpms({ \"off\" }))'";
          on-resume = "${hyprctl} eval 'hl.dispatch(hl.dsp.dpms({ \"on\" }))'";
        }

        # 4. SUSPEND
        {
          timeout = 600;
          on-timeout = checkPlayingAndRun "systemctl suspend";
        }
      ];
    };
  };
}
