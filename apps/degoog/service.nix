{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../modules/docker/oci-framework.nix { inherit lib config vars; };

  serviceName = "degoog";
  serviceHostname = "search";
  servicePort = 4444;

  appContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.web.exposed_gatekeeper { inherit serviceHostname servicePort serviceName; })
    {
      image = "ghcr.io/degoog-org/degoog:0.22.0";

      environment = {
        "DEGOOG_DISTRUST_PROXY" = "0";
        "PUID" = toString vars.dockerUser.uid;
        "PGID" = toString vars.dockerUser.gid;
      };

      volumes = [
        "${vars.dir.nixos_config}/apps/degoog/app-data:/app/data"
      ];

      ports = [];
      networks = [];
      
      labels = {};
      dependsOn = [];
      user = "";
    }
  ];

in {
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;
}