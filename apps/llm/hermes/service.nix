{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };

  serviceName = "hermes";
  serviceHostname = "hermes";
  servicePort = 9119; # dashboard,  also exposes 8642 for gateway API
  serviceId = 42;

  appContainerConfig = oci-framework.mergeAll [
    (oci-framework.web.internal { 
      inherit serviceName serviceId serviceHostname servicePort; 
      requiresInternet = "true";
    })

    {
      image = "nousresearch/hermes-agent:v2026.9.14";

      environment = {
        "HERMES_DASHBOARD" = "1";
      };

      volumes = [
        "${vars.dir.nixos_config}/apps/llm/hermes/app-data:/opt/data"
      ];

      cmd = [
        "gateway" "run"
      ];

      user = ""; # starts as root then uses normal account for running
    }
  ];

in {
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;

  systemd.services = oci-framework.mkNetwork { inherit serviceName serviceId; };
}
