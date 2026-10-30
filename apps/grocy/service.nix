{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };

  serviceName = "grocy";
  serviceId = 19;

  grocyServiceHostname = "grocy";
  grocyServicePort = 80;
  
  b2gServiceHostname = "b2g";
  b2gServicePort = 8000;

  appContainerConfig = oci-framework.mergeAll [
    (oci-framework.web.internal {
      inherit serviceName serviceId; 
      serviceHostname = grocyServiceHostname; 
      servicePort = grocyServicePort;
    })
    {
      image = "lscr.io/linuxserver/grocy:v4.7.1-ls341";

      volumes = [
        "${vars.dir.nixos_config}/apps/grocy/app-data:/config"
      ];

      user = "";  # linuxserver image, sets user after startup using env
    }
  ];

  b2gcontainerConfig = oci-framework.mergeAll [
    (oci-framework.web.internal { 
      inherit serviceName serviceId; 
      serviceHostname = b2gServiceHostname; 
      servicePort = b2gServicePort;
      containerId = 4;    # avoid colision with grocy with cid 2
    })
    {
      image = "ghcr.io/tomasinjo/barcode-to-grocy:1.0.3";

      environment = {
        "APP_LOG_FILE" = ""; # log to stdout
        "GROCY_BASE_URL" = "http://${serviceName}-app";
        "GROCY_API_KEY" = vars.apps.grocy.api_key;
        "GROCY_VERIFY_TLS" = "false";
        "LOG_LEVEL" = "DEBUG";
      };
    }
  ];

in {
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;
  virtualisation.oci-containers.containers."${serviceName}-bg2" = b2gcontainerConfig;
  systemd.services = oci-framework.mkNetwork { inherit serviceName serviceId; };
}