{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../modules/docker/oci-framework.nix { inherit lib config vars; };

  serviceName = "victoriametrics";
  serviceHostname = "logs";
  servicePort = 9428;

  appContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.web.internal { inherit serviceHostname servicePort serviceName; })
    {
      image = "docker.io/victoriametrics/victoria-logs:v1.50.0";

      environment = {};

      volumes = [
        "${vars.dir.nixos_config}/apps/victorialogs/app-data:/victoria-logs-data"
      ];

      ports = [
        "127.0.0.1:9428:9428"
      ];

      networks = [
        "logging-net"
      ];
      labels = {};
      dependsOn = [];
      cmd = [
        "-storageDataPath=victoria-logs-data"
      ];
    }
  ];

in {
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;
}