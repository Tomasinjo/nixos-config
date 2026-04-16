{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../modules/docker/oci-framework.nix { inherit lib config vars; };

  serviceName = "grafana";
  serviceHostname = "graf";
  servicePort = 3000;

  appContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.web.internal { inherit serviceHostname servicePort serviceName; })
    {
      image = "grafana/grafana:13.0.0";

      environment = {
        "GF_SERVER_ROOT_URL" = "https://${serviceHostname}.${vars.net.domain}/";
        "GF_PLUGINS_PREINSTALL" = "victoriametrics-metrics-datasource";
      };

      volumes = [
        "${vars.dir.nixos_config}/apps/grafana/app-data:/var/lib/grafana"
      ];

      ports = [];

      networks = [
        "logging-net"
      ];
      
      labels = {};
      dependsOn = [];
    }
  ];

in {
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;
}