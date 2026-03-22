{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../../modules/docker/oci-framework.nix { inherit lib config vars; };

  serviceName = "homeassistant";
  serviceHostname = "ha";
  servicePort = 8123;

  dbUser = "fikus";
  dbPass = vars.apps.home-assistant.db.password;
  dbName = "hass";

  appContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.web.exposed_mtls { inherit serviceHostname servicePort; })
    {
      image = "homeassistant/home-assistant:2026.3.2";

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

      networks = [
        "ha-net"
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
    (oci-framework.apps.postgres { inherit dbUser dbPass dbName; })
    {
      volumes = [
        "${vars.dir.nixos_config}/apps/ha/home_assistant/db-data:/data/postgres"
      ];

      networks = [
        "ha-net"
      ];
    }
  ];

  mqttContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    {
      image = "eclipse-mosquitto:2.0";

      volumes = [
        "${vars.dir.nixos_config}/apps/ha/home_assistant/mqtt-data/:/mosquitto/"
      ];

      ports = [
        "${vars.net.zenki.common-vlan.ipv4Address}:1883:1883"
      ];

      networks = [
        "ha-net"
      ];
    }
  ];

in {
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;
  virtualisation.oci-containers.containers."${serviceName}-db" = dbContainerConfig;
  virtualisation.oci-containers.containers."mqtt" = mqttContainerConfig;
}