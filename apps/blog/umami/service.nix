{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../../modules/docker/oci-framework.nix { inherit lib config pkgs vars; };

  serviceName = "umami";
  serviceHostname = "umami";
  servicePort = 3000;
  serviceId = 7;

  dbUser = "umami";
  dbPass = vars.apps.umami.db.password;
  dbName = "umami";

  containerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.web.internal { inherit serviceHostname servicePort serviceName serviceId; })
    {
      image = "ghcr.io/umami-software/umami:3.3.1";

      environment = {
        "DATABASE_URL" = "postgresql://${dbUser}:${dbPass}@${serviceName}-db:5432/${dbName}";
        "APP_SECRET" = vars.apps.umami.app.secret;
      };
    }
  ];

  dbContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.apps.postgres { inherit serviceName serviceId dbUser dbPass dbName; })
    {
      volumes = [
        "${vars.dir.nixos_config}/apps/blog/umami/db-data:/data/postgres"
      ];
    }
  ];

in {
  virtualisation.oci-containers.containers."${serviceName}-app" = containerConfig;
  virtualisation.oci-containers.containers."${serviceName}-db" = dbContainerConfig;
  
  systemd.services = oci-framework.mkNetwork { inherit serviceName serviceId; };
}
