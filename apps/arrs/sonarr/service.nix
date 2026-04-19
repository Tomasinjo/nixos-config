{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../../modules/docker/oci-framework.nix { inherit lib config vars; };

  serviceName = "sonarr";
  serviceHostname = "sonarr";
  servicePort = 8989;

  appContainerConfig = oci-framework.mergeAll [
    oci-framework.base.linuxserver
    (oci-framework.web.internal { inherit serviceHostname servicePort serviceName; })
    {
      image = "lscr.io/linuxserver/sonarr:4.0.17.2952-ls308";

      environment = {};

      volumes = [
        "${vars.dir.nixos_config}/apps/arrs/sonarr/app-data:/config"
        "${vars.dir.hoarder_data}/media:/media"
      ];

      ports = [];

      networks = [
        "arr-net"
      ];
      
      labels = {};
    }
  ];

in {
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;
}