{ lib, config, pkgs, vars, ... }:


let
  oci-framework = import ../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };

  serviceName = "mealie";
  serviceHostname = "mealie";
  servicePort = 9000;
  serviceId = 44;

  dbUser = "mealie";
  dbPass = vars.apps.mealie.db.password;
  dbName = "mealie";

  appContainerConfig = oci-framework.mergeAll [
    (oci-framework.web.exposed_gatekeeper { 
      inherit serviceName serviceId serviceHostname servicePort;
      requiresInternet = "true";
    })

    {
      image = "ghcr.io/mealie-recipes/mealie:v3.28.0";

      environment = {
        "HOST_IP" = "10.0.1.2,${vars.net.zenki.containers.prefix6}:1001::2";
        "ALLOW_SIGNUP" = "false";
        "BASE_URL" = "https://${serviceHostname}.${vars.net.domain}";
        "DB_ENGINE" = "postgres";
        "POSTGRES_USER" = dbUser;
        "POSTGRES_PASSWORD" = dbPass;
        "POSTGRES_SERVER" = "${serviceName}-db";
        "POSTGRES_PORT" = "5432";
        "POSTGRES_DB" = dbName;
      };

      volumes = [
        "${vars.dir.nixos_config}/apps/mealie/app-data:/app/data/"
      ];

      labels = {
        "traefik.http.routers.mealie-share.rule" = "Host(`${serviceHostname}.${vars.net.domain}`) && PathRegexp(`^\/g\/home\/shared\/r\/(?:[A-Z,a-z,0-9]){8}-(?:[A-Z,a-z,0-9]){4}-(?:[A-Z,a-z,0-9]){4}-(?:[A-Z,a-z,0-9]){4}-(?:[A-Z,a-z,0-9]){12}$`)";
        "traefik.http.routers.mealie-share.entrypoints" = "https,http";
        "traefik.http.routers.mealie-share.tls" = "true";
        "traefik.http.routers.mealie-share.middlewares" = "gatekeeper_mealie_share@docker";
      };
    }
  ];

  dbContainerConfig = oci-framework.mergeAll [
    (oci-framework.apps.postgres { inherit serviceName serviceId dbUser dbPass dbName; })
    {
      volumes = [
        "${vars.dir.nixos_config}/apps/mealie/db-data:/data/postgres"
      ];
    }
  ];

in {
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;
  virtualisation.oci-containers.containers."${serviceName}-db" = dbContainerConfig;

  systemd.services = oci-framework.mkNetwork { inherit serviceName serviceId; };
}
