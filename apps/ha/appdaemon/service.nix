{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../../modules/docker/oci-framework.nix { inherit lib config vars; };

  serviceName = "appdaemon";
  serviceHostname = "ad";
  servicePort = 5050;

  appContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.web.internal { inherit serviceHostname servicePort; })
    {
      image = "acockburn/appdaemon:4.5.11";

      environment = {
        "HA_URL" = "http://homeassistant-app:8123";
        "HA_KEY" = vars.apps.appdaemon.hass_key;
      };

      volumes = [
        "${vars.dir.nixos_config}/apps/ha/appdaemon/app-data:/conf"
      ];

      ports = [];

      networks = [
        "ha-net"
      ];
      
      labels = {};
      dependsOn = [ ];
      user = ""; # can't run without root, fails at installing with pip

      extraOptions = [
        "--cpuset-cpus=12-19"  # eco cores
      ];
    }
  ];

in {
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;
}