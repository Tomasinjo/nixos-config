{ config, lib, pkgs, inputs, ... }:

with lib;

let
  lua = lib.generators.mkLuaInline;

in
{
  home.packages = with pkgs; [ 
    cliphist 
    playerctl 
    pavucontrol
  ];

  # create symlink to both gpus. This is to avoid using colons in AQ_DRM_DEVICE env which confuses hyprland when two or more gpus are defined. 
  xdg.configFile."hypr/igpu".source = config.lib.file.mkOutOfStoreSymlink "/dev/dri/by-path/pci-0000:00:02.0-card";
  xdg.configFile."hypr/dgpu".source = config.lib.file.mkOutOfStoreSymlink "/dev/dri/by-path/pci-0000:01:00.0-card";

  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";
    settings = {
      monitor = [
        {
          output = "desc:LG Electronics LG ULTRAWIDE 0x01010101";
          mode = "2560x1080@75";
          position = "0x0";
          scale = 1;
        }
      ];

      env = [
        {_args = ["AQ_DRM_DEVICES" "${config.xdg.configHome}/hypr/igpu"]; } # prefer iGPU (00:02) over dGPU
      ];

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
          kb_layout = "us";
          follow_mouse = 1;
        };
      };

      bind = [
        {_args = ["SUPER + T" (lua ''hl.dsp.exec_cmd("kitty")'')];}
        {_args = ["SUPER + M" (lua ''hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit")'')];}
        {_args = ["SUPER + V" (lua ''hl.dsp.exec_cmd("cliphist list | rofi -dmenu | cliphist decode | wl-copy")'')];}
        {_args = ["SUPER + R" (lua ''hl.dsp.exec_cmd("rofi -show drun")'')];}
        {_args = ["SUPER + Q" (lua ''hl.dsp.window.close()'')];}
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
        {_args = ["SUPER + 1" (lua ''hl.dsp.focus { workspace = 1 }'')];}
        {_args = ["SUPER + 2" (lua ''hl.dsp.focus { workspace = 2 }'')];}
        {_args = ["SUPER + 3" (lua ''hl.dsp.focus { workspace = 3 }'')];}
        {_args = ["SUPER + 4" (lua ''hl.dsp.focus { workspace = 4 }'')];}
        {_args = ["SUPER + 5" (lua ''hl.dsp.focus { workspace = 5 }'')];}
        {_args = ["SUPER + 6" (lua ''hl.dsp.focus { workspace = 6 }'')];}
        {_args = ["SUPER + 7" (lua ''hl.dsp.focus { workspace = 7 }'')];}
        {_args = ["SUPER + 8" (lua ''hl.dsp.focus { workspace = 8 }'')];}
        {_args = ["SUPER + 9" (lua ''hl.dsp.focus { workspace = 9 }'')];}

        {_args = ["XF86AudioRaiseVolume" (lua ''hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%+")'') {locked = true; repeating = true;} ];}
        {_args = ["XF86AudioLowerVolume" (lua ''hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%-")'') {locked = true; repeating = true;} ];}

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
              end
            '')
          ];
        }
      ];
    };
  };
}
