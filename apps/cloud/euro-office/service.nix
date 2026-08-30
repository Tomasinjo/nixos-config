{ lib, config, pkgs, vars, ... }:


let
  oci-framework = import ../../../modules/docker/oci-framework.nix { inherit lib config pkgs vars; };

  serviceName = "euro-office";
  serviceHostname = "office";
  servicePort = 80;
  serviceId = 9;

  appContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.web.exposed_gatekeeper { inherit serviceHostname servicePort serviceName serviceId; })    {
      image = "ghcr.io/euro-office/documentserver:v9.3.3";

      environment = {
        "WOPI_ENABLED" = "true";
        "USE_UNAUTHORIZED_STORAGE" = "false";
      };

      user = "";  # does not support non-root
    }
  ];


in {
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;
  systemd.services = oci-framework.mkNetwork { inherit serviceName serviceId; };
}
