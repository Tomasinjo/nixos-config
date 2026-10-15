{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };

  serviceName = "dr_sre";
  serviceId = 43;

  appContainerConfig = oci-framework.mergeAll [
    (oci-framework.core { 
      inherit serviceName serviceId; containerId = 4;
      requiresInternet = "true";
    })

    {
      image = "ghcr.io/tomasinjo/dr_sre:0.1.0";

      environment = {
        "TELEGRAM_BOT_TOKEN" = vars.telegram_bot_token;
        "TELEGRAM_CHAT_ID" = vars.telegram_allowed_users;
        "OLLAMA_BASE_URL" = "http://10.0.27.4:11434";
        "OLLAMA_MODEL" = "qwen3.8:27b-262k";
        "VICTORIALOGS_URL" = "http://10.0.37.2:9428";
        "VICTORIALOGS_TIMEOUT" = "120";
        "REPORT_HOURS" = "8,19";
      };

      volumes = [
        "${vars.dir.nixos_config}/apps/llm/dr_sre/app-data:/app/data"
      ];
    }
  ];

in {
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;

  systemd.services = oci-framework.mkNetwork { inherit serviceName serviceId; };
}
