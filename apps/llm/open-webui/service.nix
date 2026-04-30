{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../../modules/docker/oci-framework.nix { inherit lib config vars; };

  serviceName = "open-webui";
  serviceHostname = "chat";
  servicePort = 8080;

  appContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.web.exposed_gatekeeper { inherit serviceHostname servicePort serviceName; })
    {
      image = "ghcr.io/open-webui/open-webui:0.9-slim";

      environment = {
        "OLLAMA_BASE_URLS" = "http://ollama:11434";
        "ENV" = "prod";
        "WEBUI_AUTH" = "True";
        "WEBUI_NAME" = "Fikus AI Chat";
        "WEBUI_URL" = "https://${serviceHostname}.${vars.net.domain}";
        "WEBUI_SECRET_KEY" = vars.apps.open-webui.app.secret;
      };

      volumes = [
        "${vars.dir.nixos_config}/apps/llm/open-webui/app-data:/app/backend/data"
      ];

      ports = [];

      networks = [
        "llm-net"
      ];
      
      labels = {};
      dependsOn = [ "ollama" ];
      user = "";  # does not support non-root
    }
  ];

  ollamaContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    oci-framework.hardware.cuda
    {
      image = "ollama/ollama:0.22.1";

      environment = {
        "OLLAMA_KEEP_ALIVE" = "24h";
        "OLLAMA_DEBUG" = "0";
        "OLLAMA_FLASH_ATTENTION" = "1";
        "OLLAMA_KV_CACHE_TYPE" = "q4_0";
      };

      volumes = [
        "${vars.dir.nixos_config}/apps/llm/open-webui/ollama-data:/root/.ollama"
      ];

      ports = [
        "${vars.net.zenki.common-vlan.ipv4Address}:7869:11434"
      ];

      networks = [
        "llm-net"
      ];
      
      labels = {};
      user = "";  # does not support non-root
    }
  ];


in {
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;
  virtualisation.oci-containers.containers."ollama" = ollamaContainerConfig;
}