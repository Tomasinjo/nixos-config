{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../modules/docker/oci-framework.nix { inherit lib config vars; };

  serviceName = "paperless";
  serviceHostname = "papir";
  servicePort = 8000;

  dbUser = "paperless";
  dbPass = vars.apps.paperless.db.password;
  dbName = "paperless";

  appContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.web.exposed_gatekeeper { inherit serviceHostname servicePort serviceName; })
    {
      image = "ghcr.io/paperless-ngx/paperless-ngx:2.20.15";

      environment = {
        "PAPERLESS_REDIS" = "redis://${serviceName}-redis:6379";
        "PAPERLESS_DBHOST" = "${serviceName}-db";
        "USERMAP_UID" = toString vars.dockerUser.uid;
        "USERMAP_GID" = toString vars.dockerUser.gid;
        "PAPERLESS_OCR_LANGUAGES" = "slv";
        "PAPERLESS_URL" = "https://${serviceHostname}.${vars.net.domain}";
        "PAPERLESS_ADMIN_USER" = "fikus";
        "PAPERLESS_ADMIN_PASSWORD" = vars.apps.paperless.app.admin_password;
      };

      volumes = [
        "${vars.dir.nixos_config}/apps/paperless/app-data:/usr/src/paperless/data"
        "${vars.dir.nixos_config}/apps/paperless/app-media:/usr/src/paperless/media"
        "${vars.dir.impo_data}/paperless/archive:/usr/src/paperless/media/documents/archive"
        "${vars.dir.impo_data}/paperless/consume:/usr/src/paperless/consume"
      ];

      ports = [];

      networks = [
        "paperless-net"
      ];
      
      labels = {};

      user = "";  # the image support non-root container by default
    }
  ];

  dbContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.apps.postgres { inherit dbUser dbPass dbName; })
    {
      volumes = [
        "${vars.dir.nixos_config}/apps/paperless/db-data:/data/postgres"
      ];

      networks = [
        "paperless-net"
      ];
    }
  ];

  redisContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    {
      image = "docker.io/library/redis:7.4.8";

      environment = {};

      volumes = [
        "${vars.dir.nixos_config}/apps/paperless/redis-data:/data"
      ];

      ports = [];

      networks = [
        "paperless-net"
      ];
      
      labels = {};
    }
  ];

  paperllamaContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
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

      ports = [];

      networks = [
        "paperless-net"
        "llm-net"
      ];
      
      labels = {};

      cmd = ["python" "main.py" "--mode" "auto"];
    }
  ];

in {
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;
  virtualisation.oci-containers.containers."${serviceName}-db" = dbContainerConfig;
  virtualisation.oci-containers.containers."${serviceName}-redis" = redisContainerConfig;
  virtualisation.oci-containers.containers."${serviceName}-llama" = paperllamaContainerConfig;
}