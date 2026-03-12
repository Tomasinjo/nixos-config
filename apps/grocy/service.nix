{ lib, config, pkgs, vars, ... }:

let
  secrets = import ../../secrets.nix;
  grocySecrets = secrets.apps.grocy;

  oci-framework = import ../../modules/docker/oci-framework.nix { inherit lib vars; };

  serviceName = "grocy";
  servicePort = 80;

  containerConfig = oci-framework.merge 
    (oci-framework.templates.web-internal { inherit serviceName servicePort; })
    {
      image = "lscr.io/linuxserver/grocy:v4.5.0-ls316";

      # Overwrite user to match original compose, as the linuxserver image handles PUID/PGID internally
      user = "";

      environment = {
        PUID = grocySecrets.puid;
        PGID = grocySecrets.pgid;
        TZ = grocySecrets.tz;
      };

      volumes = [
        "${vars.dir.nixos_configs}/apps/grocy/app-data:/config"
      ];
    };

in {
  virtualisation.oci-containers.containers."${serviceName}-app" = containerConfig;
}