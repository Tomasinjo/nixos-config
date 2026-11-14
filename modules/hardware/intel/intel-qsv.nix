{ lib, config, pkgs, ... }:

{
  options.hardware.intel-qsv = {
    groupId = lib.mkOption {
      type = lib.types.int;
      default = 303;
      description = "The GID of the render group";
    };
    deviceNode = lib.mkOption {
      type = lib.types.str;
      default = "/dev/dri/renderD128";
      description = "The device node for Intel QSV";
    };
  };

  config = {
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

    # Ensure the render group gets the expected GID
    users.groups.render.gid = config.hardware.intel-qsv.groupId;
  };
}
