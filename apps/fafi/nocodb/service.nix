{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../../modules/docker/oci-framework.nix { inherit lib config vars; };

  serviceName = "nocodb";
  serviceHostname = "noco";
  servicePort = 8080;

  dbUser = "fikus";
  dbPass = vars.apps.nocodb.db.password;
  dbName = "fafimiga";

  appContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.web.exposed_gatekeeper { inherit serviceHostname servicePort; })
    {
      image = "nocodb/nocodb:0.301.3";

      environment = {
        "NC_DB" = "pg://fafi-db:5432?u=${dbUser}&p=${dbPass}&d=${dbName}";
        "NC_PUBLIC_URL" = "https://${serviceHostname}.${vars.networking.domain}";
        "NC_DISABLE_TELE" = "true";
      };

      volumes = [
        "${vars.dir.nixos_config}/apps/fafi/nocodb/app-data:/usr/app/data"
      ];

      ports = [];

      networks = [
        "fafi-net"
      ];
      
      labels = {};
      dependsOn = [ "fafi-db" ];
    }
  ];

  dbContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.apps.postgres { inherit dbUser dbPass dbName; })
    {
      volumes = [
        "${vars.dir.nixos_config}/apps/fafi/nocodb/db-data:/data/postgres"
      ];

      networks = [
        "fafi-net"
      ];
    }
  ];

in {
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;
  virtualisation.oci-containers.containers."fafi-db" = dbContainerConfig;
}