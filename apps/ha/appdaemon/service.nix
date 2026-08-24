{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../../modules/docker/oci-framework.nix { inherit lib config pkgs vars; };

  serviceName = "appdaemon";
  serviceHostname = "ad";
  servicePort = 5050;
  serviceId = 20;

  appContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.web.internal { inherit serviceHostname servicePort serviceName serviceId; })
    {
      image = "acockburn/appdaemon:4.5.13";

      environment = {
        "HA_URL" = "http://home-assistant-app:8123";
        "HA_KEY" = vars.apps.appdaemon.hass_key;
      };

      volumes = [
        "${vars.dir.nixos_config}/apps/ha/appdaemon/app-data:/conf"
      ];

      networks = [
        "home-assistant-net"
      ];
      
      user = ""; # can't run without root, fails at installing with pip

      extraOptions = [
        "--cpuset-cpus=12-19"  # eco cores
      ];
    }
  ];

in {
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;
  systemd.services = oci-framework.mkNetwork { inherit serviceName serviceId; };
}