{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../../modules/docker/oci-framework.nix  { inherit lib config vars; };

  serviceName = "radarr";
  serviceHostname = "radarr";
  servicePort = 7878;

  containerConfig = oci-framework.mergeAll [
    oci-framework.base.linuxserver
    (oci-framework.web.internal { inherit serviceHostname servicePort serviceName; })
    {
      image = "linuxserver/radarr:6.0.4.10291-ls293";

      environment = {};

      volumes = [
        "${vars.dir.nixos_config}/apps/arrs/radarr/app-data:/config"
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
  virtualisation.oci-containers.containers."${serviceName}-app" = containerConfig;
}