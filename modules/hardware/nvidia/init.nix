{ config, lib, pkgs, ... }:
{
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false; # allows deep sleep states
    open = false;
    nvidiaPersistenced = false; # if enabled, it keeps gpu alive
    #package = config.boot.kernelPackages.nvidiaPackages.latest;
    package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
#      version = "595.71.05";
#      sha256_64bit = "sha256-NiA7iWC35JyKQva6H1hjzeNKBek9KyS3mK8G3YRva4I=";
#      sha256_aarch64 = "sha256-Z/7IvEEa/XfZ5F5qoSIPvXJLGtscYVqjFxHZaN/M2Ts=";
#      openSha256 = "sha256-Lfz71QWKM6x/jD2B22SWpUi7/og30HRlXg1kL3EWzEw=";
#      settingsSha256 = "sha256-mXnf3jyvznfB3OfKd657rxv0rYHQb/dX/Riw/+N9EKU=";
#      persistencedSha256 = "sha256-Z/6IvEEa/XfZ5F5qoSIPvXJLGtscYVqjFxHZaN/M2Ts=";

    version = "610.43.02";
    sha256_64bit = "sha256-MDSgVLtM33dS/43CclZMsQVROAS/9TU4lFkBsWyndGM=";
    sha256_aarch64 = "sha256-isWTnokUA/dzWocFBLalnk4+O5gSExVjs3dVpdYTU88=";
    openSha256 = "sha256-hP5NVZZ4vGsACHLmUDKq4uckpd/kn1GxCSYnnJfAuBs=";
    settingsSha256 = "sha256-0YAhufRgjDW+uR+kjaTb154fibpcDw8QowfrucoZsKE=";
    persistencedSha256 = "sha256-Whgv9X+v2fRhzliOl2LzltY9v1SxDafFfv3IUPqj/hk=";
};

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
  imports = [
    ./nvidia-fan-control.nix
  ];
}
