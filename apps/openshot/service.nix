{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };

  serviceName = "openshot";
  serviceHostname = "openshot";
  servicePort = 3000;
  serviceId = 29;


  appContainerConfig = oci-framework.mergeAll [
    oci-framework.base.linuxserver
    (oci-framework.web.internal { inherit serviceHostname servicePort serviceName serviceId; })
    oci-framework.hardware.quicksync
    {
      image = "lscr.io/linuxserver/openshot:v3.5.1-ls66";

      environment = {
        "PIXELFLUX_WAYLAND" = "true";
        "DRINODE" = "/dev/dri/renderD128";
        "DRI_NODE" = "/dev/dri/renderD128";
      };

      volumes = [
        "${vars.dir.nixos_config}/apps/openshot/app-data:/config"
      ];
    }
  ];


in {
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;
  systemd.services = oci-framework.mkNetwork { inherit serviceName serviceId; };
}