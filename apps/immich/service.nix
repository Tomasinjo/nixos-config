{ lib, config, pkgs, vars, ... }:

let
  oci = import ../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };
  svc = oci.service { name = "immich"; id = 23; dir = ./.; };

  hostname_mtls = "im";
  hostname_gk = "img";

  dbUser = "postgres";
  dbName = "immich";

in
  svc.build {
    app = svc.container {
      web = { 
        host = hostname_mtls;
        port = 2283; 
        expose = "mtls";
      };
      internet = false;
      image = "ghcr.io/immich-app/immich-server:v3.4.1";
      mounts = [
        "thumbs:/data/thumbs"
      ];
      extraMounts = [
        "${vars.dir.impo_data}/immich:/data"
      ];
      environment = {
        DB_USERNAME = dbUser;
        DB_DATABASE_NAME = dbName;
        DB_HOSTNAME = svc.containerName "db";
        REDIS_HOSTNAME = svc.containerName "redis";
      };
      secrets = { 
        DB_PASSWORD = "apps/immich/db/password";
      };
      hardware = [ "quicksync" ];  # video transcoding
      labels = {
        "traefik.enable" = "true";

        # This is for home assistant for wall photoframe
        "traefik.http.middlewares.immich-cors.headers.accessControlAllowOriginList" = "https://ha.${vars.net.domain}";
        "traefik.http.middlewares.immich-cors.headers.accessControlAllowMethods" = "GET, PUT, POST, DELETE, OPTIONS";
        "traefik.http.middlewares.immich-cors.headers.accessControlAllowHeaders" = "X-Api-Key, User-Agent, Content-Type";
        "traefik.http.middlewares.immich-cors.headers.accessControlMaxAge" = "1728000";

        # Access with gatekeeper's whitelist, mostly for links sharing
        "traefik.http.routers.immich-main.rule" = "Host(`${hostname_gk}.${vars.net.domain}`)";
        "traefik.http.routers.immich-main.entrypoints" = "https,http";
        "traefik.http.routers.immich-main.tls" = "true";
        "traefik.http.routers.immich-main.middlewares" = "immich-cors,dynamic-whitelist@file";

        # Access by mTLS (oci-framework configures it)
        "traefik.http.routers.${hostname_mtls}.middlewares" = "immich-cors";

        # Gatekeeper whitelists IPs that access a valid share link
        "traefik.http.routers.immich-share.rule" = "Host(`${hostname_gk}.${vars.net.domain}`) && PathRegexp(`^\/share\/(?:[A-Z,a-z,0-9,_,-]){67}$`)";
        "traefik.http.routers.immich-share.entrypoints" = "https,http";
        "traefik.http.routers.immich-share.middlewares" = "gatekeeper_immich_share@docker";
        "traefik.http.routers.immich-share.tls" = "true";
      };
    };

    db = svc.db {
      user = dbUser;
      database = dbName;
      image = "ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0@sha256:bcf63357191b76a916ae5eb93464d65c07511da41e3bf7a8416db519b40b1c23";
      environment = {
        "POSTGRES_INITDB_ARGS" = "'--data-checksums'";
      };
    };

    redis = svc.container {
      id = 4;
      internet = false;
      image = "docker.io/valkey/valkey:9@sha256:c123e3715db63d06d4ad6964884037aa0d5d4d703939b9929954112889708e1d";
      mounts = [ "/data"];
    };

    ml = svc.container {
      id = 5;
      internet = false;
      image = "ghcr.io/immich-app/immich-machine-learning:v3.4.1-openvino";
      mounts = [
        "model-cache:/cache"
        "dotcache:/.cache"
        "config:/.config"
      ];
      environment = {
        "MACHINE_LEARNING_MODEL_TTL" = "300";
      };
      hardware = [ "quicksync" ]; # face classification
    };
  }