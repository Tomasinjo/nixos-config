{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../modules/docker/oci-framework.nix { inherit lib config vars; };

  serviceName = "grafana";
  serviceHostname = "graf";
  servicePort = 3000;

  appContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.web.internal { inherit serviceHostname servicePort; })
    {
      image = "grafana/grafana:12.4.2";

      environment = {
        "GF_SERVER_ROOT_URL" = "https://${serviceHostname}.${vars.net.domain}/";
        "GF_PLUGINS_PREINSTALL" = "";
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