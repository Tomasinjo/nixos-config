{ config, lib, pkgs, inputs, hyprland, ... }:

with lib;

let
  cfg = config.wayland.hyprland;

  baseSettings = {
    monitor = [ 
      "desc:LG Electronics LG ULTRAWIDE 0x01010101, 2560x1080@75, 0x0, 1"
    ];

    "$terminal" = "kitty";
    "$fileManager" = "kitty yazi";
    "$menu" = "rofi -show drun";

    exec-once = [
      "hyprpaper"
      "hyprlock"
      "wl-paste --type text --watch cliphist store"
      "wl-paste --type image --watch cliphist store"
      "waybar"
    ];

    general = {
      gaps_in = 5;
      gaps_out = 5;
      border_size = 2;
      "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 90deg";
      "col.inactive_border" = "rgba(595959aa)";
      layout = "dwindle";
    };

    decoration = {
      rounding = 10;
      blur = { enabled = true; size = 3; passes = 1; };
    };

    input = {
      kb_layout = "si";
      follow_mouse = 1;
      touchpad.natural_scroll = false;
    };
    "$mainMod" = "SUPER";
    bind = [
      "$mainMod, L, exec, hyprlock"
      "$mainMod,Q,exec,$terminal"
      "$mainMod,C,killactive,"
      "$mainMod,M,exec,command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit"
      "$mainMod,E,exec,$fileManager"
      "$mainMod,V,exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy"
      "$mainMod,R,exec,$menu"
      "$mainMod,P,pseudo,"
      "$mainMod,J,togglesplit,"
      "$mainMod,left,movefocus,l"
      "$mainMod,right,movefocus,r"
      "$mainMod,up,movefocus,u"
      "$mainMod,down,movefocus,d"
      "$mainMod,1,workspace,1"
      "$mainMod,2,workspace,2"
      "$mainMod,3,workspace,3"
      "$mainMod,4,workspace,4"
      "$mainMod,5,workspace,5"
      "$mainMod,6,workspace,6"
      "$mainMod,7,workspace,7"
      "$mainMod,8,workspace,8"
      "$mainMod,9,workspace,9"
      "$mainMod,0,workspace,10"
      "$mainMod SHIFT,1,movetoworkspace,1"
      "$mainMod SHIFT,2,movetoworkspace,2"
      "$mainMod SHIFT,3,movetoworkspace,3"
      "$mainMod SHIFT,4,movetoworkspace,4"
      "$mainMod SHIFT,5,movetoworkspace,5"
      "$mainMod SHIFT,6,movetoworkspace,6"
      "$mainMod SHIFT,7,movetoworkspace,7"
      "$mainMod SHIFT,8,movetoworkspace,8"
      "$mainMod SHIFT,9,movetoworkspace,9"
      "$mainMod SHIFT,0,movetoworkspace,10"
      "$mainMod,S,togglespecialworkspace,magic"
      "$mainMod SHIFT,S,movetoworkspace,special:magic"
      "$mainMod,mouse_down,workspace,e+1"
      "$mainMod,mouse_up,workspace,e-1"
      "$mainMod,KP_End,workspace,1"
      "$mainMod,KP_Down,workspace,2"
      "$mainMod,KP_Next,workspace,3"
      "$mainMod,KP_Left,workspace,4"
      "$mainMod,KP_Begin,workspace,5"
      "$mainMod,KP_Right,workspace,6"
      "$mainMod,KP_Home,workspace,7"
      "$mainMod,KP_Up,workspace,8"
      "$mainMod,KP_Prior,workspace,9"
      ",KP_End,movetoworkspace,1"
      ",KP_Down,movetoworkspace,2"
      ",KP_Next,movetoworkspace,3"
      ",KP_Left,movetoworkspace,4"
      ",KP_Begin,movetoworkspace,5"
      ",KP_Right,movetoworkspace,6"
      ",KP_Home,movetoworkspace,7"
      ",KP_Up,movetoworkspace,8"
      ",KP_Prior,movetoworkspace,9"
      ",XF86Calculator, exec, rofi -show calc -modi calc -no-show-match -no-sort"
    ];
    
    bindel = [ 
      ",XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+" 
      ",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
    ];
    bindl = [ 
      ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
      ", XF86AudioPlay, exec, playerctl play-pause"
      ", XF86AudioPrev, exec, playerctl previous"
      ", XF86AudioNext, exec, playerctl next"    
    ];
    
    bindm = [ "$mainMod,mouse:272,movewindow" ];
  };

in
{
  options.wayland.hyprland = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Hyprland";
    };
    settings = mkOption {
      type = types.attrs;
      default = {};
      description = "Host-specific Hyprland attribute settings";
    };
  };

  config = mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      enable = true;
      package = hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      
      settings = recursiveUpdate baseSettings cfg.settings // {
        # recursiveUpdate merges sets, but it overwrites lists.
        # So we manually concatenate the important lists:
        exec-once = (baseSettings.exec-once or []) ++ (cfg.settings.exec-once or []);
        bind = (baseSettings.bind or []) ++ (cfg.settings.bind or []);
        bindel = (baseSettings.bindel or []) ++ (cfg.settings.bindel or []);
        windowrule = (baseSettings.windowrule or []) ++ (cfg.settings.windowrule or []);
        workspace = (baseSettings.workspace or []) ++ (cfg.settings.workspace or []);
	monitor =  (baseSettings.monitor or []) ++ (cfg.settings.monitor or []);
	env =  (baseSettings.env or []) ++ (cfg.settings.env or []);
      };
    };

    home.packages = with pkgs; [ cliphist brightnessctl playerctl ];
  };
}
