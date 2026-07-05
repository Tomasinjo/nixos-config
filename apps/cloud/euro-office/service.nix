{ lib, config, pkgs, vars, ... }:


let
  oci-framework = import ../../../modules/docker/oci-framework.nix { inherit lib config vars; };

  serviceName = "euro-office";
  serviceHostname = "office";
  servicePort = 80;

  appContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.web.exposed_gatekeeper { inherit serviceHostname servicePort serviceName; })    {
      image = "ghcr.io/euro-office/documentserver:v9.3.2";

      environment = {
        "WOPI_ENABLED" = "true";
        "USE_UNAUTHORIZED_STORAGE" = "false";
      };

      volumes = [];

      ports = [];

      networks = [
        "cloud-net"
      ];
      
      labels = {};

      user = "";  # does not support non-root
    }
  ];


in {
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;
}
