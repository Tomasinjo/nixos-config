{ lib, config, pkgs, vars, ... }:

let
  oci = import ../../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };
  svc = oci.service { name = "dr_sre"; id = 43; dir = ./.; };

in
  svc.build {
    app = svc.container {
      internet = true;
      image = "ghcr.io/tomasinjo/dr_sre:0.1.0";
      mounts = [ "/app/data" ];
      environment = {
        OLLAMA_BASE_URL = "http://10.0.27.2:11434";
        OLLAMA_MODEL = "qwen3.8:27b-262k";
        VICTORIALOGS_URL = "http://10.0.37.2:9428";
        VICTORIALOGS_TIMEOUT = "120";
        REPORT_HOURS = "8,19";
      };
      secrets = {
        TELEGRAM_BOT_TOKEN = "ext/telegram_bot_token";
        TELEGRAM_CHAT_ID = "ext/telegram_allowed_users";
      };
    };
  }