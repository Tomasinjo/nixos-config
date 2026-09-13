{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };

  serviceName = "esphome";
  serviceHostname = "eh";
  servicePort = 6052;
  serviceId = 21;

  appContainerConfig = oci-framework.mergeAll [
    (oci-framework.web.internal { 
      inherit serviceName serviceId serviceHostname servicePort; 
      requiresInternet = "true"; # dependency downloads
    })
    {
      image = "esphome/esphome:2026.8.2";

      environment = {
        "USERNAME" = vars.apps.esphome.username;
        "PASSWORD" = vars.apps.esphome.password;
        "ESPHOME_DASHBOARD_USE_PING" = "true";
      };

      volumes = [
        "${vars.dir.nixos_config}/apps/ha/esphome/app-data:/config"
      ];

      user = ""; # fails if run as user: PermissionError: [Errno 13] Permission denied: '/.platformio'
    }
  ];

in {
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;
  systemd.services = oci-framework.mkNetwork { inherit serviceName serviceId; };
}