{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../../modules/docker/oci-framework.nix { inherit lib config vars; };

  serviceName = "lightdash";
  serviceHostname = "lightdash";
  servicePort = 8080;

  dbUser = "PGUSER";
  dbPass = vars.apps.lightdash.db.password;
  dbName = "lightdash";

  minioContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    {
      image = "coollabsio/minio:RELEASE.2025-10-15T17-29-55Z";

      environment = {
        "MINIO_ROOT_USER" = vars.apps.lightdash.minio.user;
        "MINIO_ROOT_PASSWORD" = vars.apps.lightdash.minio.password;
        "MINIO_DEFAULT_BUCKETS" = "default";
      };

      volumes = [
        "${vars.dir.nixos_config}/apps/fafi/lightdash/minio-data/init-minio.sh:/init-minio.sh"
        "${vars.dir.nixos_config}/apps/fafi/lightdash/minio-data:/data"
      ];

      ports = [
        #"${vars.net.zenki.common-vlan.ipv4Address}:9000:9000"
        #"${vars.net.zenki.common-vlan.ipv4Address}:9001:9001" # for minio console
      ];

      networks = [
        "lightdash-net"
      ];
      
      labels = {};

      entrypoint = "/init-minio.sh";
    }
  ];

  appContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.web.internal { inherit serviceHostname servicePort; })
    {
<<<<<<< HEAD
      image = "lightdash/lightdash:0.2644.1";
=======
      image = "lightdash/lightdash:0.2682.2";
>>>>>>> d77319e9b9a8b8dc87a973320b35076d0602b5dc

      environment = {
        "PGHOST" = "${serviceName}-db";
        "PGPORT" = "5432";
        "PGUSER" = dbUser;
        "PGPASSWORD" = dbPass;
        "PGDATABASE" = dbName;
        "SECURE_COOKIES" = "false";
        "TRUST_PROXY" = "true";
        "LIGHTDASH_SECRET" = vars.apps.lightdash.lightdash.secret;
        "PORT" = toString servicePort;
        "SITE_URL" = "https://${serviceHostname}.${vars.net.domain}";
        "LIGHTDASH_LOG_LEVEL" = "info";
        "LIGHTDASH_INSTALL_ID" = "";
        "LIGHTDASH_INSTALL_TYPE" = "docker_image";
        "LIGHTDASH_LICENSE_KEY" = "";
        "ALLOW_MULTIPLE_ORGS" = "false";
        "LIGHTDASH_QUERY_MAX_LIMIT" = "5000";
        "LIGHTDASH_MAX_PAYLOAD" = "5mb";
        #"HEADLESS_BROWSER_HOST" = "headless-browser";
        #"HEADLESS_BROWSER_PORT" = "3000";
        "USE_SECURE_BROWSER" = "";
        "SCHEDULER_ENABLED" = "true";
        "GROUPS_ENABLED" = "false";
        "SERVICE_ACCOUNT_ENABLED" = "false";
        "NODE_ENV" = "production";
        # https://docs.lightdash.com/self-host/customize-deployment/environment-variables
      };

      volumes = [
        "${vars.dir.nixos_config}/apps/fafi/lightdash/app-data:/usr/app/dbt"
      ];

      ports = [];

      networks = [
        "lightdash-net"
        "fafi-net"
      ];
      
      labels = {};

      user = "";  # the thing doesnt run without root
    }
  ];

  dbContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.apps.postgres { inherit dbUser dbPass dbName; })
    {
      volumes = [
        "${vars.dir.nixos_config}/apps/fafi/lightdash/db-data:/data/postgres"
      ];

      networks = [
        "lightdash-net"
      ];
    }
  ];

in {
  virtualisation.oci-containers.containers."${serviceName}-minio" = minioContainerConfig;
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;
  virtualisation.oci-containers.containers."${serviceName}-db" = dbContainerConfig;
}