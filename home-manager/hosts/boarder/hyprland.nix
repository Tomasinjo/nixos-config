
{ config, pkgs, inputs, vars, ... }:

{
  wayland.hyprland = {
    settings = {
    # Boarder specific Hyprland settings
      cursor = {
        hide_on_touch = true;
        inactive_timeout = 1; # Hides it immediately after 1 second on boot before your first touch
      };
      exec-once = [
        "env MOZ_ENABLE_WAYLAND=1 firefox  --kiosk \"https://search.${vars.net.domain}\""
      ];
    };
  };
}
