{ lib, config, pkgs, vars, ... }:

let
  oci = import ../../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };
  svc = oci.service { name = "home-assistant"; id = 22; dir = ./.; };

  dbUser = "fikus";
  dbName = "hass";

in
  svc.build {
    app = svc.container {
      web = { 
        host = "ha";
        port = 8123; 
        expose = "mtls";
      };
      internet = true;  # cloud integrations, weather
      image = "homeassistant/home-assistant:2026.11.1";
      mounts = [
        "config:/config"
        "media:/media"
      ];
      extraMounts = [ "/dev/serial/by-id:/dev/serial/by-id" ];
      environment = {};  # PUID and GUID are passed by default
      labels = {
        "traefik.http.routers.ha.service" = "ha_service@file";
      };
      user = ""; # it is set by env vars
      devices = [
        "/dev/ttyUSB0:/dev/ttyUSB0" # zigbee
      ];
      capabilities = {
        "NET_RAW" = true;
      };
    };

    db = svc.db {
      user = dbUser;
      database = dbName;
    };

    mqtt = svc.container {
      id = 4;
      internet = false;
      image = "eclipse-mosquitto:2.0";
      mounts = [
        "config:/mosquitto/config"
        "data:/mosquitto/data"
        "log:/mosquitto/log"
      ];
    };
  }