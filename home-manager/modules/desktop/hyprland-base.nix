{ config, lib, pkgs, inputs, hostName, ... }:

with lib;

let
  cfg = config.wayland.hyprland;
  lua = lib.generators.mkLuaInline;


  baseSettings = {
    config = {
      general = {
        gaps_in = 5;
        gaps_out = 5;
        border_size = 2;
        col.active_border = {
          colors = ["rgba(33ccffee)" "rgba(00ff99ee)"]; 
          angle = 90;
        };
        col.inactive_border = "rgba(595959aa)";
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
    };

    bind = [
      {_args = ["SUPER + L" (lua ''hl.dsp.exec_cmd("hyprlock")'')];}
      {_args = ["SUPER + Q" (lua ''hl.dsp.exec_cmd("kitty")'')];}
      {_args = ["SUPER + M" (lua ''hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit")'')];}
      {_args = ["SUPER + E" (lua ''hl.dsp.exec_cmd("kitty yazi")'')];}
      {_args = ["SUPER + V" (lua ''hl.dsp.exec_cmd("cliphist list | rofi -dmenu | cliphist decode | wl-copy")'')];}
      {_args = ["SUPER + R" (lua ''hl.dsp.exec_cmd("rofi -show drun")'')];}
      {_args = ["SUPER + C" (lua ''hl.dsp.window.close()'')];}
      {_args = ["SUPER + left" (lua ''hl.dsp.focus { direction = "l" }'')];}
      {_args = ["SUPER + right" (lua ''hl.dsp.focus { direction = "r" }'')];}
      {_args = ["SUPER + up" (lua ''hl.dsp.focus { direction = "u" }'')];}
      {_args = ["SUPER + down" (lua ''hl.dsp.focus { direction = "d" }'')];}
      {_args = ["SUPER + SHIFT + 1" (lua ''hl.dsp.window.move({ workspace = "1" })'')];}
      {_args = ["SUPER + SHIFT + 2" (lua ''hl.dsp.window.move({ workspace = 2 })'')];}
      {_args = ["SUPER + SHIFT + 3" (lua ''hl.dsp.window.move({ workspace = 3 })'')];}
      {_args = ["SUPER + SHIFT + 4" (lua ''hl.dsp.window.move({ workspace = 4 })'')];}
      {_args = ["SUPER + SHIFT + 5" (lua ''hl.dsp.window.move({ workspace = 5 })'')];}
      {_args = ["SUPER + SHIFT + 6" (lua ''hl.dsp.window.move({ workspace = 6 })'')];}
      {_args = ["SUPER + SHIFT + 7" (lua ''hl.dsp.window.move({ workspace = 7 })'')];}
      {_args = ["SUPER + SHIFT + 8" (lua ''hl.dsp.window.move({ workspace = 8 })'')];}
      {_args = ["SUPER + SHIFT + 9" (lua ''hl.dsp.window.move({ workspace = 9 })'')];}
      {_args = ["SUPER + ALT + up" (lua ''hl.dsp.window.resize({ x = 0, y = -60, relative = true })'')];}
      {_args = ["SUPER + ALT + down" (lua ''hl.dsp.window.resize({ x = 0, y = 60, relative = true })'')];}
      {_args = ["SUPER + ALT + left" (lua ''hl.dsp.window.resize({ x = -60, y = 0, relative = true })'')];}
      {_args = ["SUPER + ALT + right" (lua ''hl.dsp.window.resize({ x = 60, y = 0, relative = true })'')];}
      {_args = ["SUPER + S" (lua ''hl.dsp.workspace.toggle_special("magic")'')];}
      {_args = ["SUPER + 1" (lua ''hl.dsp.focus { workspace = 1 }'')];}
      {_args = ["SUPER + 2" (lua ''hl.dsp.focus { workspace = 2 }'')];}
      {_args = ["SUPER + 3" (lua ''hl.dsp.focus { workspace = 3 }'')];}
      {_args = ["SUPER + 4" (lua ''hl.dsp.focus { workspace = 4 }'')];}
      {_args = ["SUPER + 5" (lua ''hl.dsp.focus { workspace = 5 }'')];}
      {_args = ["SUPER + 6" (lua ''hl.dsp.focus { workspace = 6 }'')];}
      {_args = ["SUPER + 7" (lua ''hl.dsp.focus { workspace = 7 }'')];}
      {_args = ["SUPER + 8" (lua ''hl.dsp.focus { workspace = 8 }'')];}
      {_args = ["SUPER + 9" (lua ''hl.dsp.focus { workspace = 9 }'')];}
      {_args = ["KP_End" (lua ''hl.dsp.window.move({ workspace = 1 })'')];}
      {_args = ["KP_Down" (lua ''hl.dsp.window.move({ workspace = 2 })'')];}
      {_args = ["KP_Next" (lua ''hl.dsp.window.move({ workspace = 3 })'')];}
      {_args = ["KP_Left" (lua ''hl.dsp.window.move({ workspace = 4 })'')];}
      {_args = ["KP_Begin" (lua ''hl.dsp.window.move({ workspace = 5 })'')];}
      {_args = ["KP_Right" (lua ''hl.dsp.window.move({ workspace = 6 })'')];}
      {_args = ["KP_Home" (lua ''hl.dsp.window.move({ workspace = 7 })'')];}
      {_args = ["KP_Up" (lua ''hl.dsp.window.move({ workspace = 8 })'')];}
      {_args = ["KP_Prior" (lua ''hl.dsp.window.move({ workspace = 9 })'')];}
      {_args = ["XF86Calculator" (lua ''hl.dsp.exec_cmd("rofi -show calc -modi calc -no-show-match -no-sort")'')];}

      {_args = ["XF86AudioRaiseVolume" (lua ''hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+")'') {locked = true; repeating = true;} ];}
      {_args = ["XF86AudioLowerVolume" (lua ''hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-")'') {locked = true; repeating = true;} ];}

      {_args = ["XF86AudioMute" (lua ''hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")'') {locked = true;} ];}
      {_args = ["XF86AudioPlay" (lua ''hl.dsp.exec_cmd("playerctl play-pause")'') {locked = true;} ];}
      {_args = ["XF86AudioPrev" (lua ''hl.dsp.exec_cmd("playerctl previous")'') {locked = true;} ];}
      {_args = ["XF86AudioNext" (lua ''hl.dsp.exec_cmd("playerctl next")'') {locked = true;} ];}

      {_args = ["SUPER + mouse:272" (lua ''hl.dsp.window.drag()'')];}
    ];

    on = [
      {
        _args = [
          "hyprland.start"
          (lua ''
            function()
              hl.exec_cmd("wl-paste --type text --watch cliphist store")
              hl.exec_cmd("wl-paste --type image --watch cliphist store")
              ${optionalString (attrByPath [ "wayland" "hyprpaper" "enable" ] false config) ''hl.exec_cmd("hyprpaper")''}
              ${optionalString (attrByPath [ "wayland" "hyprlock" "enable" ] false config) ''hl.exec_cmd("hyprlock")''}
              ${optionalString (attrByPath [ "wayland" "waybar" "enable" ] false config) ''hl.exec_cmd("waybar")''}
            end
          '')
        ];
      }
    ];
  };

in
{
  imports = [
    ../../hosts/${hostName}/hyprland.nix
  ];
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
      configType = "lua";
      settings = recursiveUpdate baseSettings cfg.settings // {
        # recursiveUpdate merges sets, but it overwrites lists.
        # So we manually concatenate the important lists:
        on = baseSettings.on ++ (cfg.settings.on or []);
        bind = (baseSettings.bind or []) ++ (cfg.settings.bind or []);
        window_rule = (baseSettings.window_rule or []) ++ (cfg.settings.window_rule or []);
        workspace_rule = (baseSettings.workspace_rule or []) ++ (cfg.settings.workspace_rule or []);
	      monitor =  (baseSettings.monitor or []) ++ (cfg.settings.monitor or []);
	      env =  (baseSettings.env or []) ++ (cfg.settings.env or []);
      };
    };

    home.packages = with pkgs; [ 
      cliphist 
      playerctl 
      pavucontrol
    ];
  };
}
