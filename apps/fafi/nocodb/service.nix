{ lib, config, pkgs, vars, ... }:

let
  oci = import ../../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };
  svc = oci.service { name = "nocodb"; id = 15; dir = ./.; };

  dbUser = "fikus";
  dbName = "fafimiga";
  hostname = "noco";

in
  svc.build {
    app = svc.container {
      web = { 
        host = hostname;
        port = 8080; 
        expose = "gatekeeper";
      };
      internet = false;
      image = "nocodb/nocodb:0.301.5";
      mounts = [ "/usr/app/data" ];
      environment = {
        NC_DISABLE_TELE = "true";
        NC_PUBLIC_URL = "https://${hostname}.${vars.net.domain}";
      };
      secrets = { 
        NC_DB = "apps/nocodb/db/url";
      };
    };

    db = svc.db {
      user = dbUser;
      database = dbName;
    };
  }