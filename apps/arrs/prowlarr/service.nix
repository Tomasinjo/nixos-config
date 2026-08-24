{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../../modules/docker/oci-framework.nix { inherit lib config pkgs vars; };

  serviceName = "prowlarr";
  serviceHostname = "prowlarr";
  servicePort = 9696;
  serviceId = 3;

  containerConfig = oci-framework.mergeAll [
    oci-framework.base.linuxserver
    (oci-framework.web.internal { inherit serviceHostname servicePort serviceName serviceId; })
    {
      image = "lscr.io/linuxserver/prowlarr:2.5.2.5491-ls156";

      volumes = [
        "${vars.dir.nixos_config}/apps/arrs/prowlarr/app-data:/config"
      ];
    }
  ];

in {
  virtualisation.oci-containers.containers."${serviceName}-app" = containerConfig;
  systemd.services = oci-framework.mkNetwork { inherit serviceName serviceId; };
}