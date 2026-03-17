{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../../modules/docker/oci-framework.nix { inherit lib config vars; };

  serviceName = "metabase";
  serviceHostname = "fafi";
  servicePort = 3000;

  dbUser = "metabase";
  dbPass = vars.apps.metabase.db.password;
  dbName = "metabaseappdb";

  appContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.web.exposed_gatekeeper { inherit serviceHostname servicePort; })
    {
      image = "metabase/metabase:v0.58.x";

      environment = {
        "MB_DB_TYPE" = "postgres";
        "MB_DB_DBNAME" = dbName;
        "MB_DB_PORT" = "5432";
        "MB_DB_USER" = dbUser;
        "MB_DB_PASS" = dbPass;
        "MB_DB_HOST" = "${serviceName}-db";
      };

      volumes = [
        "/dev/urandom:/dev/random:ro"
      ];

      ports = [];

      networks = [
        "metabase-net"
        "fafi-net"
      ];
      
      labels = {};

      dependsOn = [ "${serviceName}-db" ];
    }
  ];

  dbContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.apps.postgres { inherit dbUser dbPass dbName; })
    {
      volumes = [
        "${vars.dir.nixos_config}/apps/fafi/metabase/db-data:/data/postgres"
      ];

      networks = [
        "metabase-net"
      ];
    }
  ];

in {
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;
  virtualisation.oci-containers.containers."${serviceName}-db" = dbContainerConfig;
}