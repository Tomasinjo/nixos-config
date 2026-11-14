{ lib, config, pkgs, vars, ... }:

let
  oci = import ../../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };
  svc = oci.service { name = "hermes"; id = 42; dir = ./.; };

in
  svc.build {
    app = svc.container {
      web = { 
        host = "hermes";
        port = 9119;  # dashboard, also exposes 8642 for gateway API
        expose = "internal";
      };
      internet = true;
      image = "nousresearch/hermes-agent:v0.22.5";
      mounts = [ "/opt/data" ];
      environment = {
        HERMES_DASHBOARD = "1";
      };
      secrets = {
        GLM_API_KEY = "ext/glm_api_key";
      };
      cmd = [ "gateway" "run" ];
      user = ""; # starts as root then uses normal account for running
    };
  }