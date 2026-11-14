{ lib, config, pkgs, vars, ... }:

let
  oci = import ../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };
  svc = oci.service { name = "fatracker-ng"; id = 45; dir = ./.; };

  dbUser = "fatracker";
  dbName = "fatracker";

in
  svc.build {
    app = svc.container {
      web = { 
        host = "fatracker";
        port = 8000; 
        expose = "gatekeeper";
      };
      internet = true; # for strong
      image = "ghcr.io/tomasinjo/fatracker-ng:1.1.2";
      mounts = [ "/data" ];
      environment = {
        REPORT_TIMEZONE = "Europe/Ljubljana";
      };
      secrets = { 
        DATABASE_URL = "apps/fatracker-ng/db/url";
        WEBHOOK_API_KEY = "apps/fatracker-ng/webhook_api_key";
        MCP_TOKEN = "apps/fatracker-ng/mcp_api_key";
        STRONG_EMAIL = "ext/strong/email";
        STRONG_PASSWORD = "ext/strong/password";
      };
    };

    db = svc.db {
      user = dbUser;
      database = dbName;
    };
  }