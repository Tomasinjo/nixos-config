{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../../modules/docker/oci-framework.nix { inherit lib config vars; };

  serviceName = "umami";
  serviceHostname = "umami";
  servicePort = 3000;

  dbUser = "umami";
  dbPass = vars.apps.umami.db.password;
  dbName = "umami";

  containerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.web.internal { inherit serviceHostname servicePort; })
    {
      image = "ghcr.io/umami-software/umami:3.0.3";

      environment = {
        "DATABASE_URL" = "postgresql://${dbUser}:${dbPass}@${serviceName}-db:5432/${dbName}";
        "APP_SECRET" = vars.apps.umami.app.secret;
      };

      networks = [
        "umami-net"
      ];
    }
  ];

  dbContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.apps.postgres { inherit dbUser dbPass dbName; })
    {
      volumes = [
        "${vars.dir.nixos_config}/apps/blog/umami/db-data:/data/postgres"
      ];

      networks = [
        "umami-net"
      ];
    }
  ];

in {
  virtualisation.oci-containers.containers."${serviceName}-app" = containerConfig;
  virtualisation.oci-containers.containers."${serviceName}-db" = dbContainerConfig;
}
