{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../../modules/docker/oci-framework.nix  { inherit lib config pkgs vars; };

  serviceName = "radarr";
  serviceHostname = "radarr";
  servicePort = 7878;
  serviceId = 5;

  containerConfig = oci-framework.mergeAll [
    oci-framework.base.linuxserver
    (oci-framework.web.internal { inherit serviceHostname servicePort serviceName serviceId; })
    {
      image = "linuxserver/radarr:6.0.4.10291-ls293";

      volumes = [
        "${vars.dir.nixos_config}/apps/arrs/radarr/app-data:/config"
        "${vars.dir.hoarder_data}/media:/media"
      ];
    }
  ];

in {
  virtualisation.oci-containers.containers."${serviceName}-app" = containerConfig;
  systemd.services = oci-framework.mkNetwork { inherit serviceName serviceId; };
}