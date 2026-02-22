{ config, pkgs, ... }:
{
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
# the following two are disabled due to suspicion of causing high idle power
#    powerManagement.finegrained = true; # allows deep sleep states
#    open = true; 
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    
    # the following allows running desktop with iGPU, while selectively offloading programs to nvidia. 
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true; # Creates the 'nvidia-offload' command.. run program with nvidia with "nvidia-offload steam"
      };
      # lspci | grep -E 'VGA|3D'
      intelBusId =  "PCI:00:02:0"; 
      nvidiaBusId = "PCI:01:00:0";
    };
  };

  hardware.nvidia-container-toolkit.enable = true;
  boot.kernelParams = [ "iomem=relaxed" ]; # for running gddr6-core-junction-vram-temps
  systemd.services.nvidia-persistenced.enable = false;
}
