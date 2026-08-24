{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../../modules/docker/oci-framework.nix { inherit lib config pkgs vars; };

  serviceName = "home-assistant";
  serviceHostname = "ha";
  servicePort = 8123;
  serviceId = 22;

  dbUser = "fikus";
  dbPass = vars.apps.home-assistant.db.password;
  dbName = "hass";

  appContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.web.exposed_mtls { inherit serviceHostname servicePort serviceName serviceId; })
    {
      image = "homeassistant/home-assistant:2026.8.2";

      environment = {
        "PUID" = toString vars.dockerUser.uid;
        "GUID" = toString vars.dockerUser.gid;
      };

      volumes = [
        "${vars.dir.nixos_config}/apps/ha/home_assistant/app-data:/config"
        "${vars.dir.nixos_config}/apps/ha/home_assistant/app-media:/media"
        "/dev/serial/by-id:/dev/serial/by-id"
      ];

      ports = [
        "${vars.net.zenki.common-vlan.ipv4Address}:5683:5683/udp"  # shelly em3 CoIoT"
      ];
      
      labels = {
        "traefik.http.routers.${serviceHostname}.service" = "ha_service@file";
      };

      user = ""; # it is set by env vars

      devices = [
        "/dev/ttyUSB0:/dev/ttyUSB0" # zigbee
      ];

      capabilities = {
        "NET_RAW" = true;
      };
    }
  ];

  dbContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.apps.postgres { inherit serviceName serviceId dbUser dbPass dbName; })
    {
      volumes = [
        "${vars.dir.nixos_config}/apps/ha/home_assistant/db-data:/data/postgres"
      ];
    }
  ];

  mqttContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.container { inherit serviceName serviceId; containerId = 4; })
    {
      image = "eclipse-mosquitto:2.0";

      volumes = [
        "${vars.dir.nixos_config}/apps/ha/home_assistant/mqtt-data/config:/mosquitto/config"
        "${vars.dir.nixos_config}/apps/ha/home_assistant/mqtt-data/data:/mosquitto/data"
        "${vars.dir.nixos_config}/apps/ha/home_assistant/mqtt-data/log:/mosquitto/log"
      ];

      ports = [
        "${vars.net.zenki.common-vlan.ipv4Address}:1883:1883"
      ];
    }
  ];

in {
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;
  virtualisation.oci-containers.containers."${serviceName}-db" = dbContainerConfig;
  virtualisation.oci-containers.containers."mqtt" = mqttContainerConfig;
  
  systemd.services = oci-framework.mkNetwork { inherit serviceName serviceId; };
}
