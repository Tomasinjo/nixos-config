{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };

  serviceName = "immich";
  serviceHostname = "im";
  servicePort = 2283;
  serviceId = 23;

  alternateServiceHostname = "img";

  dbUser = "postgres";
  dbPass = vars.apps.immich.db.password;
  dbName = "immich";

  appContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.web.exposed_mtls { inherit serviceHostname servicePort serviceName serviceId; })
    oci-framework.hardware.quicksync
    {
      image = "ghcr.io/immich-app/immich-server:v3.1.0";

      environment = {
        "DB_USERNAME" = dbUser;
        "DB_PASSWORD" = dbPass;
        "DB_DATABASE_NAME" = dbName;
        "DB_HOSTNAME" = "${serviceName}-db";
        "REDIS_HOSTNAME" = "${serviceName}-redis";
      };

      volumes = [
        #"${vars.dir.impo_data}/immich:/usr/src/app/upload"
        "${vars.dir.impo_data}/immich:/data"
        "${vars.dir.nixos_config}/apps/immich/app-data/thumbs:/data/thumbs"
      ];

      labels = {
        "traefik.enable" = "true";

        # This is for home assistant for wall photoframe
        "traefik.http.middlewares.immich-cors.headers.accessControlAllowOriginList" = "https://ha.${vars.net.domain}";
        "traefik.http.middlewares.immich-cors.headers.accessControlAllowMethods" = "GET, PUT, POST, DELETE, OPTIONS";
        "traefik.http.middlewares.immich-cors.headers.accessControlAllowHeaders" = "X-Api-Key, User-Agent, Content-Type";
        "traefik.http.middlewares.immich-cors.headers.accessControlMaxAge" = "1728000";

        # Access with gatekeeper's whitelist, mostly for links sharing
        "traefik.http.routers.immich-main.rule" = "Host(`${alternateServiceHostname}.${vars.net.domain}`)";
        "traefik.http.routers.immich-main.entrypoints" = "https,http";
        "traefik.http.routers.immich-main.tls" = "true";
        "traefik.http.routers.immich-main.middlewares" = "immich-cors,dynamic-whitelist@file";

        # Access by mTLS (oci-framework configures it)
        "traefik.http.routers.${serviceHostname}.middlewares" = "immich-cors";

        # Gatekeeper whitelists IPs that access a valid share link
        "traefik.http.routers.immich-share.rule" = "Host(`${alternateServiceHostname}.${vars.net.domain}`) && PathRegexp(`^\/share\/(?:[A-Z,a-z,0-9,_,-]){67}$`)";
        "traefik.http.routers.immich-share.entrypoints" = "https,http";
        "traefik.http.routers.immich-share.middlewares" = "gatekeeper_immich_share@docker";
        "traefik.http.routers.immich-share.tls" = "true";
      };
    }
  ];

  dbContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.db { inherit serviceName serviceId; })
    {
      image = "ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0@sha256:bcf63357191b76a916ae5eb93464d65c07511da41e3bf7a8416db519b40b1c23";
      
      environment = {
        "POSTGRES_PASSWORD" = dbPass;
        "POSTGRES_USER" = dbUser;
        "POSTGRES_DB" = dbName;
        "POSTGRES_INITDB_ARGS" = "'--data-checksums'";
      };
      
      volumes = [
        "${vars.dir.nixos_config}/apps/immich/db-data:/var/lib/postgresql/data"
      ];

      extraOptions = [
        "--shm-size=128m"
      ];
    }
  ];

  redisContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.container { inherit serviceName serviceId; containerId = 4; })
    {
      image = "docker.io/valkey/valkey:9@sha256:546304417feac0874c3dd576e0952c6bb8f06bb4093ea0c9ca303c73cf458f63";
      
      volumes = [
        "${vars.dir.nixos_config}/apps/immich/redis-data:/data"
      ];
    }
  ];


  mlContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.container { inherit serviceName serviceId; containerId = 5; })
    oci-framework.hardware.quicksync
    {
      image = "ghcr.io/immich-app/immich-machine-learning:v3.1.0-openvino";
      
      environment = {
        "MACHINE_LEARNING_MODEL_TTL" = "300";
      };
      
      volumes = [
        "${vars.dir.nixos_config}/apps/immich/ml-data/model-cache:/cache"
        "${vars.dir.nixos_config}/apps/immich/ml-data/dotcache:/.cache"
        "${vars.dir.nixos_config}/apps/immich/ml-data/config:/.config"
      ];
    }
  ];


in {
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;
  virtualisation.oci-containers.containers."${serviceName}-db" = dbContainerConfig;
  virtualisation.oci-containers.containers."${serviceName}-redis" = redisContainerConfig;
  virtualisation.oci-containers.containers."${serviceName}-machine-learning" = mlContainerConfig;

  systemd.services = oci-framework.mkNetwork { inherit serviceName serviceId; };
}
