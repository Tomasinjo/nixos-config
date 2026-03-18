{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../modules/docker/oci-framework.nix { inherit lib config vars; };

  serviceName = "teslamate";
  
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
        }
    )
    {
      image = "teslamate/grafana:3.0.0";

      environment = {
        "DATABASE_USER" = dbUser;
        "DATABASE_PASS" = dbPass;
        "DATABASE_NAME" = dbName;
        "DATABASE_HOST" = "teslamate-db"; 
      };

      volumes = [
        "${vars.dir.nixos_config}/apps/teslamate/app-data:/var/lib/grafana"
      ];

      ports = [];

      networks = [
        "tesla-net"
      ];
      
      labels = {};
      dependsOn = [ "${serviceName}-db" ];
    }
  ];

  dbContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.apps.postgres { inherit dbUser dbPass dbName; })
    {
      volumes = [
        "${vars.dir.nixos_config}/apps/teslamate/db-data:/data/postgres"
      ];

      networks = [
        "tesla-net"
      ];
    }
  ];

  appContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.web.internal {  
            serviceHostname = teslamateServiceHostname;
            servicePort = teslamateServicePort;  
        }
    )
    {
      image = "teslamate/teslamate:3.0.0";

      environment = {
        "ENCRYPTION_KEY" = vars.apps.teslamate.app.key;
        "DATABASE_USER" = dbUser;
        "DATABASE_PASS" = dbPass;
        "DATABASE_NAME" = dbName;
        "DATABASE_HOST" = "${serviceName}-db";
        "MQTT_HOST"     = "mqtt";
        "MQTT_USERNAME" = vars.apps.mqtt.user;
        "MQTT_PASSWORD" = vars.apps.mqtt.password;
      };

      volumes = [
        "${vars.dir.nixos_config}/apps/teslamate/app-data:/var/lib/grafana"
      ];

      ports = [];

      networks = [
        "tesla-net"
        "ha-net"
      ];
      
      labels = {};
      dependsOn = [ "${serviceName}-db" ];
    }
  ];


in {
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;
  virtualisation.oci-containers.containers."${serviceName}-grafana" = grafanaContainerConfig;
  virtualisation.oci-containers.containers."${serviceName}-db" = dbContainerConfig;
}