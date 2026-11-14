{ lib, config, pkgs, vars, ... }:

let
  oci = import ../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };
  svc = oci.service { name = "teslamate"; id = 32; dir = ./.; };

  dbUser = "teslamate";
  dbName = "teslamate";

in
  svc.build {
    app = svc.container {
      web = { 
        host = "teslamate";
        port = 4000; 
        expose = "internal";
      };
      internet = true;
      image = "teslamate/teslamate:4.4.0";
      environment = {
        "DATABASE_USER" = dbUser;
        "DATABASE_NAME" = dbName;
        "DATABASE_HOST" = svc.containerName "db";
        "MQTT_HOST"     = "10.0.22.4";
      };
      secrets = { 
        ENCRYPTION_KEY = "apps/teslamate/app/key"; 
        DATABASE_PASS  = "apps/teslamate/db/password";
        MQTT_USERNAME  = "apps/mqtt/user";
        MQTT_PASSWORD  = "apps/mqtt/password";
      };
      labels = {
        "glance.name" = "TeslaMate";
      };
    };

    grafana = svc.container {
      id = 4;
      web = { 
        host = "tesla";
        port = 3000; 
        expose = "internal";
      };
      internet = false;
      image = "teslamate/grafana:4.4.0";
      mounts = [ "/var/lib/grafana" ];
      environment = {
        DATABASE_USER = dbUser;
        DATABASE_NAME = dbName;
        DATABASE_HOST = svc.containerName "db"; 
      };
      secrets = { 
        DATABASE_PASS = "apps/teslamate/db/password";
      };
      labels = {
        "glance.name" = "Tesla Dashboards";
        "fikus.name" = "Tesla"; # Custom display names for bookmarks
      };
    };

    db = svc.db {
      user = dbUser;
      database = dbName;
    };
  }