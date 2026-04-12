{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../../modules/docker/oci-framework.nix { inherit lib config vars; };

  serviceName = "pinchflat";
  serviceHostname = "tube";
  servicePort = 8945;

  containerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.web.internal { inherit serviceHostname servicePort serviceName; })
    {
      image = "keglin/pinchflat:v2025.6.6";

      environment = {
        "LOG_LEVEL" = "info";
      };

      volumes = [
        "${vars.dir.nixos_config}/apps/arrs/pinchflat/app-data:/config"
        "${vars.dir.hoarder_data}/media/library/tube:/downloads"
      ];

      ports = [];
      networks = [];
      labels = {};
    }
  ];

in {
  virtualisation.oci-containers.containers."${serviceName}-app" = containerConfig;
}