{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../modules/docker/oci-framework.nix { inherit lib config pkgs vars; };

  serviceName = "paperless";
  serviceHostname = "papir";
  servicePort = 8000;
  serviceId = 30;

  dbUser = "paperless";
  dbPass = vars.apps.paperless.db.password;
  dbName = "paperless";

  appContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.web.exposed_gatekeeper { inherit serviceHostname servicePort serviceName serviceId; })
    {
      image = "ghcr.io/paperless-ngx/paperless-ngx:3.0.5";

      environment = {
        "PAPERLESS_REDIS" = "redis://${serviceName}-redis:6379";
        "PAPERLESS_DBENGINE" = "postgresql";
        "PAPERLESS_DBHOST" = "${serviceName}-db";
        "USERMAP_UID" = toString vars.dockerUser.uid;
        "USERMAP_GID" = toString vars.dockerUser.gid;
        "PAPERLESS_OCR_LANGUAGES" = "slv";
        "PAPERLESS_URL" = "https://${serviceHostname}.${vars.net.domain}";
        "PAPERLESS_ADMIN_USER" = "fikus";
        "PAPERLESS_ADMIN_PASSWORD" = vars.apps.paperless.app.admin_password;
        "PAPERLESS_SECRET_KEY" = vars.apps.paperless.app.secret_key;
        "PAPERLESS_CONSUMER_DELETE_DUPLICATES" = "true";
      };

      volumes = [
        "${vars.dir.nixos_config}/apps/paperless/app-data:/usr/src/paperless/data"
        "${vars.dir.nixos_config}/apps/paperless/app-media:/usr/src/paperless/media"
        "${vars.dir.impo_data}/paperless/archive:/usr/src/paperless/media/documents/archive"
        "${vars.dir.impo_data}/paperless/consume:/usr/src/paperless/consume"
      ];

      user = "";  # the image support non-root container by default
    }
  ];

  dbContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.apps.postgres { inherit serviceName serviceId dbUser dbPass dbName; })
    {
      volumes = [
        "${vars.dir.nixos_config}/apps/paperless/db-data:/data/postgres"
      ];
    }
  ];

  redisContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.container { inherit serviceName serviceId; containerId = 4; })
    {
      image = "docker.io/library/redis:7.4.11";

      volumes = [
        "${vars.dir.nixos_config}/apps/paperless/redis-data:/data"
      ];
    }
  ];

  paperllamaContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.container { inherit serviceName serviceId; containerId = 5; })
    {
      image = "ghcr.io/tomasinjo/paper-llama:main";

      environment = {
        "PAPERLESS_URL" = "https://${serviceHostname}.${vars.net.domain}";
        "PAPERLESS_TOKEN" = vars.apps.paperless.app.api_key;
        "OLLAMA_URL" = "http://ollama:11434";
        "OLLAMA_MODEL" = "gemma3:27b-32k";
        "SCAN_INTERVAL" = "3600";
        "OVERRIDE_EXISTING_TAGS" = "True";
        "LOG_LEVEL" = "INFO";
        "OCR_SOURCE" = "llm";  # llm or paperless
        "LLM_OCR_SOURCE_PAGE_LIMIT" = "20"; # Applicable when "OCR_SOURCE=llm". If document has more pages, paperless OCR will be used
      };

      volumes = [
        "${vars.dir.nixos_config}/apps/paperless/paperllama-data/prompt.txt:/app/prompt.txt:ro"
      ];

      networks = [
        "open-webui-net"
      ];

      cmd = ["python" "main.py" "--mode" "auto"];
    }
  ];

in {
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;
  virtualisation.oci-containers.containers."${serviceName}-db" = dbContainerConfig;
  virtualisation.oci-containers.containers."${serviceName}-redis" = redisContainerConfig;
  virtualisation.oci-containers.containers."${serviceName}-llama" = paperllamaContainerConfig;

  systemd.services = oci-framework.mkNetwork { inherit serviceName serviceId; };
}