{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../modules/docker/oci-framework.nix { inherit lib config vars; };

  serviceName = "dawarich";
  serviceHostname = "dawarich";
  servicePort = 3000;

  dbUser = "dawarich";
  dbPass = vars.apps.dawarich.db.password;
  dbName = "dawarich";

  appContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.web.exposed_gatekeeper { inherit serviceHostname servicePort serviceName; })
    {
      image = "freikin/dawarich:1.6.1";

      environment = {
        "RAILS_ENV" = "production";
        "REDIS_URL" = "redis://${serviceName}-redis:6379";
        "DATABASE_HOST" = "${serviceName}-db";
        "DATABASE_PORT" = "5432";
        "DATABASE_USERNAME" = dbUser;
        "DATABASE_PASSWORD" = dbPass;
        "DATABASE_NAME" = dbName;
        "APPLICATION_HOSTS" = "localhost,${serviceHostname}.${vars.net.domain}";
        "TIME_ZONE" = "Europe/Ljubljana";
        "APPLICATION_PROTOCOL" = "http";
        "PROMETHEUS_EXPORTER_ENABLED" = "false";
        "PROMETHEUS_EXPORTER_HOST" = "0.0.0.0";
        "PROMETHEUS_EXPORTER_PORT" = "9394";
        "SECRET_KEY_BASE" = vars.apps.dawarich.app.secret;
        "RAILS_LOG_TO_STDOUT" = "true";
        "SELF_HOSTED" = "true";
        "STORE_GEODATA" = "true";
      };

      volumes = [
        "${vars.dir.nixos_config}/apps/dawarich/app-data/public:/var/app/public"
        "${vars.dir.nixos_config}/apps/dawarich/app-data/watched:/var/app/tmp/imports/watched"
        "${vars.dir.nixos_config}/apps/dawarich/app-data/storage:/var/app/storage"
        "${vars.dir.nixos_config}/apps/dawarich/db-data:/dawarich_db_data"
      ];

      ports = [];

      networks = [
        "dawarich-net"
	"immich-net"
      ];
      
      labels = {};
      entrypoint = "web-entrypoint.sh";
      cmd = [
        "bin/rails"
        "server"
        "-p"
        "3000"
        "-b"
        "::"
      ];
      #user = "";
    }
  ];

  # unstandard: inherits from postgres, but overrides the image, variables are same
  dbContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    {
      image = "postgis/postgis:17-3.5-alpine";

      environment = {
        POSTGRES_USER = dbUser;
        POSTGRES_PASSWORD = dbPass;
        POSTGRES_DB = dbName;
      };

      volumes = [
        "${vars.dir.nixos_config}/apps/dawarich/db-data:/var/lib/postgresql/data"
        "${vars.dir.nixos_config}/apps/dawarich/shared-data:/var/shared"
      ];

      networks = [
        "dawarich-net"
      ];

      extraOptions = [
        "--shm-size=1G"
      ];
    }
  ];


  redisContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    {
      image = "redis:7.4-alpine";
      volumes = [
        "${vars.dir.nixos_config}/apps/dawarich/shared-data:/data"
      ];

      networks = [
        "dawarich-net"
      ];

      cmd = [
        "redis-server" 
        "--save" "900" "1" 
        "--save" "300" "10" 
        "--appendonly" "no"
      ];
    }
  ];

  # mostly same as app container. sidekiq is specific to ruby, something related to running tasks that take long time to completed.
  # redis is used for communication between sidekiq and app.
  sidekiqContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    {
      image = "freikin/dawarich:1.6.1";

      environment = {
        "RAILS_ENV" = "production";
        "REDIS_URL" = "redis://${serviceName}-redis:6379";
        "DATABASE_HOST" = "${serviceName}-db";
        "DATABASE_PORT" = "5432";
        "DATABASE_USERNAME" = dbUser;
        "DATABASE_PASSWORD" = dbPass;
        "DATABASE_NAME" = dbName;
        "APPLICATION_HOSTS" = "localhost,${serviceHostname}.${vars.net.domain}";
        "TIME_ZONE" = "Europe/Ljubljana";
        "APPLICATION_PROTOCOL" = "http";
        "PROMETHEUS_EXPORTER_ENABLED" = "false";
        "PROMETHEUS_EXPORTER_HOST" = "0.0.0.0";
        "PROMETHEUS_EXPORTER_PORT" = "9394";
        "SECRET_KEY_BASE" = vars.apps.dawarich.app.secret;
        "RAILS_LOG_TO_STDOUT" = "true";
        "SELF_HOSTED" = "true";
        "STORE_GEODATA" = "true";
      };

      volumes = [
        "${vars.dir.nixos_config}/apps/dawarich/app-data/public:/var/app/public"
        "${vars.dir.nixos_config}/apps/dawarich/app-data/watched:/var/app/tmp/imports/watched"
        "${vars.dir.nixos_config}/apps/dawarich/app-data/storage:/var/app/storage"
      ];

      ports = [];

      networks = [
        "dawarich-net"
      ];
      
      labels = {};
      entrypoint = "sidekiq-entrypoint.sh";
      cmd = [
        "sidekiq"
      ];
      #user = "";
    }
  ];



in {
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;
  virtualisation.oci-containers.containers."${serviceName}-db" = dbContainerConfig;
  virtualisation.oci-containers.containers."${serviceName}-redis" = redisContainerConfig;
  virtualisation.oci-containers.containers."${serviceName}-sidekiq" = sidekiqContainerConfig;
}
