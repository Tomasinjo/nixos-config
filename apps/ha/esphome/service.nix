{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../../modules/docker/oci-framework.nix { inherit lib config vars; };

  serviceName = "esphome";
  serviceHostname = "eh";
  servicePort = 6052;

  appContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.web.internal { inherit serviceHostname servicePort serviceName; })
    {
      image = "esphome/esphome:2026.4.2";

      environment = {
        "USERNAME" = vars.apps.esphome.username;
        "PASSWORD" = vars.apps.esphome.password;
        "ESPHOME_DASHBOARD_USE_PING" = "true";
      };

      volumes = [
        "${vars.dir.nixos_config}/apps/ha/esphome/app-data:/config"
      ];

      ports = [];

      networks = [
        "ha-net"
      ];
      
      labels = {};
      dependsOn = [];

      user = ""; # fails if run as user: PermissionError: [Errno 13] Permission denied: '/.platformio'
    }
  ];

in {
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;
}