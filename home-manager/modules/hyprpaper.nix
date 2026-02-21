{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.wayland.hyprpaper;
in
{
  options.wayland.hyprpaper = {
    enable = mkOption {
      type = types.bool;
      default = true;
    };
    wallpaper = mkOption {
      type = types.path;
      default = ../../wallpapers/forest.png;
    };
  };

  config = mkIf cfg.enable {
    services.hyprpaper = {
      enable = true;
      settings = {
        ipc = true;
        splash = false;
        wallpaper = [
          {
            monitor = ""; # all monitors
            path = "${cfg.wallpaper}";
          }
        ];
      };
    };
  };
}