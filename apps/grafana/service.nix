{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };

  serviceName = "grafana";
  serviceHostname = "graf";
  servicePort = 3000;
  serviceId = 18;

  appContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.web.internal { inherit serviceHostname servicePort serviceName serviceId; })
    {
      image = "grafana/grafana:13.2.0";

      environment = {
        "GF_SERVER_ROOT_URL" = "https://${serviceHostname}.${vars.net.domain}/";
        "GF_PLUGINS_PREINSTALL" = "victoriametrics-metrics-datasource";
      };

      volumes = [
        "${vars.dir.nixos_config}/apps/grafana/app-data:/var/lib/grafana"
      ];
    }
  ];

in {
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;
  systemd.services = oci-framework.mkNetwork { inherit serviceName serviceId; };
}
