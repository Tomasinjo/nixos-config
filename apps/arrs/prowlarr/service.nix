{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../../modules/docker/oci-framework.nix { inherit lib config vars; };

  serviceName = "prowlarr";
  serviceHostname = "prowlarr";
  servicePort = 9696;

  containerConfig = oci-framework.mergeAll [
    oci-framework.base.linuxserver
    (oci-framework.web.internal { inherit serviceHostname servicePort serviceName; })
    {
      image = "lscr.io/linuxserver/prowlarr:2.3.0.5236-ls137";

      volumes = [
        "${vars.dir.nixos_config}/apps/arrs/prowlarr/app-data:/config"
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