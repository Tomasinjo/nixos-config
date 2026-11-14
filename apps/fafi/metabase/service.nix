{ lib, config, pkgs, vars, ... }:

let
  oci = import ../../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };
  svc = oci.service { name = "metabase"; id = 14; dir = ./.; };

  dbUser = "metabase";
  dbName = "metabaseappdb";

in
  svc.build {
    app = svc.container {
      web = { 
        host = "fafi";
        port = 3000; 
        expose = "gatekeeper";
      };
      internet = false;
      image = "metabase/metabase:v0.58.x";
      mounts = [];
      extraMounts = [
        "/dev/urandom:/dev/random:ro"
      ];
      environment = {
        MB_DB_TYPE = "postgres";
        MB_DB_DBNAME = dbName;
        MB_DB_PORT = "5432";
        MB_DB_USER = dbUser;
        MB_DB_HOST = svc.containerName "db";
      };
      secrets = { 
        MB_DB_PASS = "apps/metabase/db/password";
      };
    };

    db = svc.db {
      user = dbUser;
      database = dbName;
    };
  }