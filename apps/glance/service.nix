{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../modules/docker/oci-framework.nix { inherit lib config pkgs vars; };

  serviceName = "glance";
  serviceHostname = "home";
  servicePort = 8080;
  serviceId = 17;

  appContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.web.internal { inherit serviceHostname servicePort serviceName serviceId; })
    {
      image = "glanceapp/glance:v0.8.5";

      environment = {
        "GITHUB_TOKEN" = vars.apps.glance.app.github_token;
      };

      volumes = [
        "${vars.dir.nixos_config}/apps/glance/app-data/config:/app/config"
        "${vars.dir.nixos_config}/apps/glance/app-data/assets:/app/assets"
      ];

      networks = [
        "dockerproxy-net"
      ];
    }
  ];

in {
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;
  systemd.services = oci-framework.mkNetwork { inherit serviceName serviceId; };
}