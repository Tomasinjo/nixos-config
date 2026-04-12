{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../modules/docker/oci-framework.nix { inherit lib config vars; };

  serviceName = "searxng";
  serviceHostname = "search";
  servicePort = 8080;

  appContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.web.exposed_gatekeeper { inherit serviceHostname servicePort serviceName; })
    {
      image = "docker.io/searxng/searxng:2026.2.28-a2108ce2e";

      environment = {
        "SEARXNG_BASE_URL" = "https://${serviceHostname}.${vars.net.domain}/";
        "SEARXNG_BIND_ADDRESS" = "0.0.0.0";
        "SEARXNG_SECRET" = vars.apps.searxng.app.secret;
      };

      volumes = [
        "${vars.dir.nixos_config}/apps/searxng/app-data:/etc/searxng:rw"
      ];

      ports = [];
      networks = [];
      labels = {};
      dependsOn = [];
      
      user = "";  # the image runs as non-root by default (uid 977)
    }
  ];

in {
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;
}