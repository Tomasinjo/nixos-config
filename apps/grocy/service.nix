{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../modules/docker/oci-framework.nix { inherit lib config pkgs vars; };

  serviceName = "grocy";
  serviceHostname = "grocy";
  servicePort = 80;
  serviceId = 19;

  containerConfig = oci-framework.mergeAll [
    oci-framework.base.linuxserver
    (oci-framework.web.internal { inherit serviceHostname servicePort serviceName serviceId; })
    {
      image = "lscr.io/linuxserver/grocy:v4.6.0-ls321";

      volumes = [
        "${vars.dir.nixos_config}/apps/grocy/app-data:/config"
      ];
    }
  ];


in {
  virtualisation.oci-containers.containers."${serviceName}-app" = containerConfig;
  systemd.services = oci-framework.mkNetwork { inherit serviceName serviceId; };
}