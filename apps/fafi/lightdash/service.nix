{ lib, config, pkgs, vars, ... }:

let
  oci = import ../../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };
  svc = oci.service { name = "lightdash"; id = 13; dir = ./.; };

  dbUser = "PGUSER";
  dbName = "lightdash";
  hostname = "lightdash";
  port = 8080;

in
  svc.build {
    app = svc.container {
      web = { 
        host = hostname;
        port = port; 
        expose = "internal";
      };
      internet = false;
      image = "lightdash/lightdash:3.116.0";
      mounts = [ "/usr/app/dbt" ];
      environment = {
        PGHOST = "${svc.containerName "db"}";
        PGPORT = "5432";
        PGUSER = dbUser;
        PGDATABASE = dbName;
        SECURE_COOKIES = "false";
        TRUST_PROXY = "true";
        PORT = toString port;
        SITE_URL = "https://${hostname}.${vars.net.domain}";
        LIGHTDASH_LOG_LEVEL = "info";
        LIGHTDASH_INSTALL_ID = "";
        LIGHTDASH_INSTALL_TYPE = "docker_image";
        LIGHTDASH_LICENSE_KEY = "";
        ALLOW_MULTIPLE_ORGS = "false";
        LIGHTDASH_QUERY_MAX_LIMIT = "5000";
        LIGHTDASH_MAX_PAYLOAD = "5mb";
        #HEADLESS_BROWSER_HOST = "headless-browser";
        #HEADLESS_BROWSER_PORT = "3000";
        USE_SECURE_BROWSER = "";
        SCHEDULER_ENABLED = "true";
        GROUPS_ENABLED = "false";
        SERVICE_ACCOUNT_ENABLED = "false";
        NODE_ENV = "production";
        # https://docs.lightdash.com/self-host/customize-deployment/environment-variables
      };
      secrets = { 
        PGPASSWORD = "apps/lightdash/db/password";
        LIGHTDASH_SECRET = "apps/lightdash/app/secret";
      };
      # autoStart = false;
      user = "";  # the thing doesnt run without root
    };

    minio = svc.container {
      id = 4;
      internet = false;
      image = "coollabsio/minio:RELEASE.2025-10-15T17-29-55Z";
      mounts = [
        "init-minio.sh:/init-minio.sh"
        "/data"
      ];
      environment = {
        MINIO_DEFAULT_BUCKETS = "default";
      };
      secrets = { 
        MINIO_ROOT_USER = "apps/lightdash/minio/user";
        MINIO_ROOT_PASSWORD = "apps/lightdash/minio/password";
      };
      entrypoint = "/init-minio.sh";
    };

    db = svc.db {
      user = dbUser;
      database = dbName;
    };
  }