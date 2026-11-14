{ lib, config, pkgs, vars, ... }:

let
  oci = import ../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };
  svc = oci.service { name = "dawarich"; id = 11; dir = ./.; };

  dbUser = "dawarich";
  dbName = "dawarich";
  hostname = "dawarich";

in
  svc.build {
    app = svc.container {
      web = { 
        host = hostname;
        port = 3000; 
        expose = "gatekeeper";
      };
      internet = false;
      image = "freikin/dawarich:1.21.0";
      mounts = [
        "public:/var/app/public"
        "watched:/var/app/tmp/imports/watched"
        "storage:/var/app/storage"
      ];
      extraMounts = [
        "${vars.dir.nixos_config}/apps/dawarich/db-data/db:/dawarich_db_data"
      ];
      environment = {
        RAILS_ENV = "production";
        REDIS_URL = "redis://${svc.containerName "redis"}:6379";
        DATABASE_HOST = svc.containerName "db";
        DATABASE_PORT = "5432";
        DATABASE_USERNAME = dbUser;
        DATABASE_NAME = dbName;
        APPLICATION_HOSTS = "localhost,${hostname}.${vars.net.domain}";
        TIME_ZONE = "Europe/Ljubljana";
        APPLICATION_PROTOCOL = "http";
        PROMETHEUS_EXPORTER_ENABLED = "false";
        PROMETHEUS_EXPORTER_HOST = "0.0.0.0";
        PROMETHEUS_EXPORTER_PORT = "9394";
        RAILS_LOG_TO_STDOUT = "true";
        SELF_HOSTED = "true";
        STORE_GEODATA = "true";
      };
      secrets = { 
        DATABASE_PASSWORD = "apps/dawarich/db/password";
        SECRET_KEY_BASE = "apps/dawarich/app/secret";
      };
      entrypoint = "web-entrypoint.sh";
      cmd = [
        "bin/rails"
        "server"
        "-p"
        "3000"
        "-b"
        "::"
      ];
    };

    db = svc.db {
      user = dbUser;
      database = dbName;
      image = "postgis/postgis:17-3.5-alpine";
      mounts = [
        "db:/data/postgres"
        "shared:/var/shared"
      ];
      extraOptions = [
        "--shm-size=1G"
      ];
    };

    redis = svc.container {
      id = 4;
      internet = false;
      image = "redis:7.4-alpine";
      extraMounts = [
        "${vars.dir.nixos_config}/apps/dawarich/db-data/shared:/data"
      ];
      cmd = [
        "redis-server" 
        "--save" "900" "1" 
        "--save" "300" "10" 
        "--appendonly" "no"
      ];
    };

  # mostly same as app container. sidekiq is specific to ruby, something related to running tasks that take long time to completed.
  # redis is used for communication between sidekiq and app.
    sidekiq = svc.container {
      id = 5;
      internet = false;
      image = "freikin/dawarich:1.21.0";
      extraMounts = [
        "${vars.dir.nixos_config}/apps/dawarich/app-data/public:/var/app/public"
        "${vars.dir.nixos_config}/apps/dawarich/app-data/watched:/var/app/tmp/imports/watched"
        "${vars.dir.nixos_config}/apps/dawarich/app-data/storage:/var/app/storage"
      ];
      environment = {
        RAILS_ENV = "production";
        REDIS_URL = "redis://${svc.containerName "redis"}:6379";
        DATABASE_HOST = svc.containerName "db";
        DATABASE_PORT = "5432";
        DATABASE_USERNAME = dbUser;
        DATABASE_NAME = dbName;
        APPLICATION_HOSTS = "localhost,${hostname}.${vars.net.domain}";
        TIME_ZONE = "Europe/Ljubljana";
        APPLICATION_PROTOCOL = "http";
        PROMETHEUS_EXPORTER_ENABLED = "false";
        PROMETHEUS_EXPORTER_HOST = "0.0.0.0";
        PROMETHEUS_EXPORTER_PORT = "9394";
        RAILS_LOG_TO_STDOUT = "true";
        SELF_HOSTED = "true";
        STORE_GEODATA = "true";
      };
      secrets = { 
        DATABASE_PASSWORD = "apps/dawarich/db/password";
        SECRET_KEY_BASE = "apps/dawarich/app/secret";
      };
      entrypoint = "sidekiq-entrypoint.sh";
      cmd = [ "sidekiq" ];
    };
  }