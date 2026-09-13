{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };

  serviceName = "prowlarr";
  serviceHostname = "prowlarr";
  servicePort = 9696;
  serviceId = 3;

  containerConfig = oci-framework.mergeAll [
    (oci-framework.web.internal { 
      inherit serviceName serviceId serviceHostname servicePort;
      requiresInternet = "true";  # indexing
    })
    {
      image = "lscr.io/linuxserver/prowlarr:2.5.2.5491-ls159";

      volumes = [
        "${vars.dir.nixos_config}/apps/arrs/prowlarr/app-data:/config"
      ];

      user = "";  # linuxserver image, sets user after startup using env
    }
  ];

in {
  virtualisation.oci-containers.containers."${serviceName}-app" = containerConfig;
  systemd.services = oci-framework.mkNetwork { inherit serviceName serviceId; };
}