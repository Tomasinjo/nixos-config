{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };

  serviceName = "teslamate";
  serviceId = 32;

  grafanaServiceHostname = "tesla";
  grafanaServicePort = 3000;

  teslamateServiceHostname = "teslamate";
  teslamateServicePort = 4000;

  dbUser = "teslamate";
  dbPass = vars.apps.teslamate.db.password;
  dbName = "teslamate";

  grafanaContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.web.internal {  
      serviceHostname = grafanaServiceHostname;
      servicePort = grafanaServicePort;
      inherit serviceName serviceId;
      containerId = 4; # Override containerId to avoid collision with app
    })
    {
      image = "teslamate/grafana:4.1.1";

      environment = {
        "DATABASE_USER" = dbUser;
        "DATABASE_PASS" = dbPass;
        "DATABASE_NAME" = dbName;
        "DATABASE_HOST" = "${serviceName}-db"; 
      };

      volumes = [
        "${vars.dir.nixos_config}/apps/teslamate/app-data:/var/lib/grafana"
      ];

      labels = {
        # Custom display names for bookmarks
        "glance.name" = "Tesla Dashboards";
        "fikus.name" = "Tesla";
      };
    }
  ];

  dbContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.apps.postgres { 
      inherit serviceName serviceId dbUser dbPass dbName; 
    })
    {
      volumes = [
        "${vars.dir.nixos_config}/apps/teslamate/db-data:/data/postgres"
      ];
    }
  ];

  appContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.web.internal {  
      serviceHostname = teslamateServiceHostname;
      servicePort = teslamateServicePort;
      inherit serviceName serviceId;
    })
    {
      image = "teslamate/teslamate:4.1.1";

      environment = {
        "ENCRYPTION_KEY" = vars.apps.teslamate.app.key;
        "DATABASE_USER" = dbUser;
        "DATABASE_PASS" = dbPass;
        "DATABASE_NAME" = dbName;
        "DATABASE_HOST" = "${serviceName}-db";
        "MQTT_HOST"     = "10.0.22.4";
        "MQTT_USERNAME" = vars.apps.mqtt.user;
        "MQTT_PASSWORD" = vars.apps.mqtt.password;
      };

      labels = {
        "glance.name" = "TeslaMate";
      };
    }
  ];

in {
  # 1. Containers
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;
  virtualisation.oci-containers.containers."${serviceName}-grafana" = grafanaContainerConfig;
  virtualisation.oci-containers.containers."${serviceName}-db" = dbContainerConfig;

  systemd.services = oci-framework.mkNetwork { inherit serviceName serviceId; };
}