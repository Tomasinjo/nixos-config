{ lib, config, pkgs, vars, ... }:

let
  oci = import ../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };
  svc = oci.service { name = "mealie"; id = 44; dir = ./.; };

  dbUser = "mealie";
  dbName = "mealie";
  hostname = "mealie";

in
  svc.build {
    app = svc.container {
      web = { 
        host = hostname;
        port = 9000; 
        expose = "gatekeeper";
      };
      internet = true;  # scraping recepies
      image = "ghcr.io/mealie-recipes/mealie:v3.29.0";
      mounts = [ "/app/data/" ];
      environment = {
        HOST_IP = "10.0.1.2,${vars.net.zenki.containers.prefix6}:1001::2";
        ALLOW_SIGNUP = "false";
        BASE_URL = "https://${hostname}.${vars.net.domain}";
        DB_ENGINE = "postgres";
        POSTGRES_USER = dbUser;
        POSTGRES_SERVER = svc.containerName "db";
        POSTGRES_PORT = "5432";
        POSTGRES_DB = dbName;
      };
      secrets = { 
        POSTGRES_PASSWORD = "apps/mealie/db/password";
      };
      labels = {
        "traefik.http.routers.mealie-share.rule" = "Host(`${hostname}.${vars.net.domain}`) && PathRegexp(`^\/g\/home\/shared\/r\/(?:[A-Z,a-z,0-9]){8}-(?:[A-Z,a-z,0-9]){4}-(?:[A-Z,a-z,0-9]){4}-(?:[A-Z,a-z,0-9]){4}-(?:[A-Z,a-z,0-9]){12}$`)";
        "traefik.http.routers.mealie-share.entrypoints" = "https,http";
        "traefik.http.routers.mealie-share.tls" = "true";
        "traefik.http.routers.mealie-share.middlewares" = "gatekeeper_mealie_share@docker";
      };
    };

    db = svc.db {
      user = dbUser;
      database = dbName;
    };
  }