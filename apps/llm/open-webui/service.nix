{ lib, config, pkgs, vars, ... }:

let
  oci = import ../../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };
  svc = oci.service { name = "open-webui"; id = 46; dir = ./.; };
  hostname = "chat";
in
  svc.build {
    app = svc.container {
      web = { 
        host = hostname;
        port = 8080; 
        expose = "gatekeeper";
      };
      internet = false;
      image = "ghcr.io/open-webui/open-webui:0.13-cuda";
      mounts = [ "/app/backend/data" ];
      environment = {
        OLLAMA_BASE_URLS = "http://10.0.27.2:11434";
        ENV = "prod";
        WEBUI_AUTH = "True";
        WEBUI_NAME = "Fikus AI Chat";
        WEBUI_URL = "https://${hostname}.${vars.net.domain}";
      };
      secrets = {
        WEBUI_SECRET_KEY = "apps/open-webui/app/secret";
      };
      user = "";  # does not support non-root
    };
  }
