{ lib, config, pkgs, vars, ... }:

let
  oci = import ../../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };
  svc = oci.service { name = "umami"; id = 7; dir = ./.; };

  dbUser = "umami";
  dbName = "umami";

in
  svc.build {
    app = svc.container {
      web = { 
        host = "umami";
        port = 3000; 
        expose = "internal";
      };
      internet = false;
      image = "ghcr.io/umami-software/umami:3.4.1";
      mounts = [];
      secrets = { 
        APP_SECRET   = "apps/umami/app/secret";
        DATABASE_URL = "apps/umami/db/url";  # not optimal, but umami only support full connection string postgresql://....
      };
    };

    db = svc.db {
      user = dbUser;
      database = dbName;
    };
  }