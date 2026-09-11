{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };

  serviceName = "glance";
  serviceHostname = "home";
  servicePort = 8080;
  serviceId = 17;

  appContainerConfig = oci-framework.mergeAll [
    (oci-framework.web.internal { 
      inherit serviceName serviceId serviceHostname servicePort; 
      requiresInternet = "true"; # news, github 
    })
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