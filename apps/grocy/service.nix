{ lib, config, pkgs, vars, ... }:

let
  oci = import ../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };
  svc = oci.service { name = "grocy"; id = 19; dir = ./.; };

in
  svc.build {
    app = svc.container {
      web = { 
        host = "grocy";
        port = 80; 
        expose = "internal";
      };
      internet = false;
      image = "lscr.io/linuxserver/grocy:v4.7.1-ls341";
      mounts = [ "/config" ];
      environment = {};
      secrets = {};
      user = "";  # linuxserver image, sets user after startup using env
    };

    b2g = svc.container {
      id = 4;
      web = { 
        host = "b2g";
        port = 8000; 
        expose = "internal";
      };
      internet = true;
      image = "ghcr.io/tomasinjo/barcode-to-grocy:1.3.4";
      mounts = [];
      environment = {
        "GROCY_BASE_URL" = "http://${svc.containerName "app"}";
        "GROCY_VERIFY_TLS" = "false";
        "APP_LOG_FILE" = ""; # log to stdout
        "LOG_LEVEL" = "DEBUG";
      };
      secrets = {
        "GROCY_API_KEY" = "apps/grocy/api_key";
        "MFP_USERNAME" = "ext/mfp/username";
        "MFP_PASSWORD" = "ext/mfp/password";
        "VKJ_TOKEN" = "ext/vkj_bearer";
      };
    };
  }