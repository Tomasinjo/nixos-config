{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../modules/docker/oci-framework.nix { inherit lib config pkgs vars; };

  serviceName = "victoriametrics";
  serviceHostname = "logs";
  servicePort = 9428;
  serviceId = 37;

  appContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.web.internal { inherit serviceHostname servicePort serviceName serviceId; })
    {
      image = "docker.io/victoriametrics/victoria-logs:v1.52.0";

      volumes = [
        "${vars.dir.nixos_config}/apps/victorialogs/app-data:/victoria-logs-data"
      ];

      cmd = [
        "-storageDataPath=victoria-logs-data"
      ];
    }
  ];

in {
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;
  systemd.services = oci-framework.mkNetwork { inherit serviceName serviceId; };
}
