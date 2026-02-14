
{ config, pkgs, inputs, ... }:
{
  
  # create symlink to both gpus. This is to avoid using colons in AQ_DRM_DEVICE env which confuses hyprland when two or more gpus are defined. 
  xdg.configFile."hypr/igpu".source = config.lib.file.mkOutOfStoreSymlink "/dev/dri/by-path/pci-0000:00:02.0-card";
  xdg.configFile."hypr/dgpu".source = config.lib.file.mkOutOfStoreSymlink "/dev/dri/by-path/pci-0000:01:00.0-card";

  # NOTES: iGPU is used to run hyprland. However, there will still be 1 process visible in nvidia-smi due to DMA-BUF sharing. This is for communication between both GPUs. When game is launched, it will be run by dGPU which will pass over frames to iGPU to show them. Monitor is plugged in to iGPU.

  wayland.hyprland = {
    settings = {
    # Zenki specific Hyprland settings
      env = [
        "AQ_DRM_DEVICES,${config.xdg.configHome}/hypr/igpu:${config.xdg.configHome}/hypr/dgpu" # prefer iGPU (00:02) over dGPU
      ];
    };
  };
}
