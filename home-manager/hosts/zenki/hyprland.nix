
{ config, pkgs, inputs, ... }:
{
  imports = [
    ./waybar.nix
  ];
  # create symlink to both gpus. This is to avoid using colons in AQ_DRM_DEVICE env which confuses hyprland when two or more gpus are defined. 
  xdg.configFile."hypr/igpu".source = config.lib.file.mkOutOfStoreSymlink "/dev/dri/by-path/pci-0000:00:02.0-card";
  xdg.configFile."hypr/dgpu".source = config.lib.file.mkOutOfStoreSymlink "/dev/dri/by-path/pci-0000:01:00.0-card";

  wayland.hyprland = {
    settings = {
    # Zenki specific Hyprland settings
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
      
    };
  };
}
