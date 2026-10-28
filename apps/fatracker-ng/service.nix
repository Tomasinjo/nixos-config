{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };

  serviceName = "fatracker-ng";
  serviceHostname = "fatracker";
  servicePort = 8000;
  serviceId = 45;

  dbUser = "fatracker";
  dbPass = vars.apps.fatracker.db_password;
  dbName = "fatracker";

  appContainerConfig = oci-framework.mergeAll [
    (oci-framework.web.exposed_gatekeeper { inherit serviceName serviceId serviceHostname servicePort; })

    {
      image = "ghcr.io/tomasinjo/fatracker-ng:1.1.1";

      environment = {
        "DATABASE_URL" = "postgresql+psycopg://${dbUser}:${dbPass}@${serviceName}-db:5432/${dbName}";
        "WEBHOOK_API_KEY" = vars.apps.fatracker.webhook_api_key;
        "MCP_TOKEN" = vars.apps.fatracker.mcp_api_key;
        "REPORT_TIMEZONE" = "Europe/Ljubljana";
        STRONG_EMAIL=vars.apps.fatracker.strong_email;
        STRONG_PASSWORD=vars.apps.fatracker.strong_password;
      };
      volumes = [
        "${vars.dir.nixos_config}/apps/fatracker-ng/app-data:/data"
      ];
    }
  ];

  dbContainerConfig = oci-framework.mergeAll [
    (oci-framework.apps.postgres { inherit serviceName serviceId dbUser dbPass dbName; })
    {
      volumes = [
        "${vars.dir.nixos_config}/apps/fatracker-ng/db-data:/data/postgres"
      ];
    }
  ];

in {
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;
  virtualisation.oci-containers.containers."${serviceName}-db" = dbContainerConfig;

  systemd.services = oci-framework.mkNetwork { inherit serviceName serviceId; };
}
