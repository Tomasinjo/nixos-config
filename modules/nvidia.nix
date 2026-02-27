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
    powerManagement.finegrained = true; # allows deep sleep states
    open = false;
    nvidiaPersistenced = true;
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
  #systemd.services.nvidia-persistenced.enable = true;
}
