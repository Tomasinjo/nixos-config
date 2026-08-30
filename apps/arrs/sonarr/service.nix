{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../../modules/docker/oci-framework.nix { inherit lib config pkgs vars; };

  serviceName = "sonarr";
  serviceHostname = "sonarr";
  servicePort = 8989;
  serviceId = 6;

  appContainerConfig = oci-framework.mergeAll [
    oci-framework.base.linuxserver
    (oci-framework.web.internal { inherit serviceHostname servicePort serviceName serviceId; })
    {
      image = "lscr.io/linuxserver/sonarr:4.0.19.2979-ls321";

      volumes = [
        "${vars.dir.nixos_config}/apps/arrs/sonarr/app-data:/config"
        "${vars.dir.hoarder_data}/media:/media"
      ];
    }
  ];

in {
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;
  systemd.services = oci-framework.mkNetwork { inherit serviceName serviceId; };
}