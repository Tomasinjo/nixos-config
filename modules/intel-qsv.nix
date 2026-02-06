{ config, pkgs, ... }:

{
  boot.initrd.kernelModules = [ "i915" ];

  environment.systemPackages = with pkgs; [
    intel-gpu-tools # intel_gpu_top
    libva-utils     # vainfo to verify transcoding
    nvtopPackages.full  #nvtop
  ];

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # Modern driver for Broadwell (2015) and newer
      intel-vaapi-driver # For older apps (optional fallback)
      vpl-gpu-rt         # Required for newer QuickSync (Qsv) versions
      libvdpau-va-gl     # Translation layer
    ];
  };
}
