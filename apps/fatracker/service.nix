{ lib, config, pkgs, vars, ... }:

# must download manually: docker pull ghcr.io/tomasinjo/fatracker:main

let
  oci-framework = import ../../modules/docker/oci-framework.nix { inherit lib config vars; };

  serviceName = "fatracker";
  serviceHostname = "fatracker";
  servicePort = 8000;

  dbUser = "fatracker";
  dbPass = vars.apps.fatracker.db.password;
  dbName = "fatracker";

  appContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.web.internal { inherit serviceHostname servicePort serviceName; })
    {
      image = "ghcr.io/tomasinjo/fatracker:main";

      environment = {
        "DATABASE_URL" = "postgresql://${dbUser}:${vars.apps.fatracker.db.password}@${serviceName}-db:5432/${dbName}";
      };

      volumes = [
        "${vars.dir.impo_data}/opencloud/storage/users/projects/a8a52960-d285-432b-a4fa-3ce95654fe1e/consume_healthconnect:/consume_healthconnect"
        "${vars.dir.impo_data}/opencloud/storage/users/projects/a8a52960-d285-432b-a4fa-3ce95654fe1e/consume_strong:/consume_strong"
      ];
      
      ports = [];

      networks = [
        "fat-net"
      ];
      
      labels = {};
    }
  ];

  dbContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.apps.postgres { inherit dbUser dbPass dbName; })
    {
      volumes = [
        "${vars.dir.nixos_config}/apps/fatracker/db-data:/data/postgres"
      ];

      ports = [
        "${vars.net.zenki.common-vlan.ipv4Address}:5430:5432"
      ];

      networks = [
        "fat-net"
      ];
    }
  ];

in {
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;
  virtualisation.oci-containers.containers."${serviceName}-db" = dbContainerConfig;
}