{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../modules/docker/oci-framework.nix { inherit lib config vars; };

  serviceName = "glance";
  serviceHostname = "home";
  servicePort = 8080;

  appContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.web.internal { inherit serviceHostname servicePort serviceName; })
    {
      image = "glanceapp/glance:v0.8.4";

      environment = {
        "GITHUB_TOKEN" = vars.apps.glance.app.github_token;
      };

      volumes = [
        "${vars.dir.nixos_config}/apps/glance/app-data/config:/app/config"
        "${vars.dir.nixos_config}/apps/glance/app-data/assets:/app/assets"
      ];

      ports = [];

      networks = [
        "dockerproxy-net"
      ];
      
      labels = {};
      dependsOn = [];
    }
  ];

in {
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;
}