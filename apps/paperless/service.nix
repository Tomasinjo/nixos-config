{ lib, config, pkgs, vars, ... }:

let
  oci = import ../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };
  svc = oci.service { name = "paperless"; id = 30; dir = ./.; };

  hostname = "papir";
  dbUser = "paperless";
  dbName = "paperless";

in
  svc.build {
    app = svc.container {
      web = { 
        host = hostname;
        port = 8000; 
        expose = "gatekeeper";
      };
      internet = false;
      image = "ghcr.io/paperless-ngx/paperless-ngx:3.4.1";
      mounts = [
        "data:/usr/src/paperless/data"
        "media:/usr/src/paperless/media"
      ];
      extraMounts = [
        "${vars.dir.impo_data}/paperless/archive:/usr/src/paperless/media/documents/archive"
        "${vars.dir.impo_data}/paperless/consume:/usr/src/paperless/consume"
      ];
      environment = {
        PAPERLESS_REDIS = "redis://${svc.containerName "redis"}:6379";
        PAPERLESS_DBENGINE = "postgresql";
        PAPERLESS_DBHOST = svc.containerName "db";
        USERMAP_UID = toString vars.containerUser.uid;
        USERMAP_GID = toString vars.containerUser.gid;
        PAPERLESS_OCR_LANGUAGES = "slv";
        PAPERLESS_URL = "https://${hostname}.${vars.net.domain}";
        PAPERLESS_ADMIN_USER = "fikus";
        PAPERLESS_CONSUMER_DELETE_DUPLICATES = "true";
      };
      secrets = { 
        PAPERLESS_ADMIN_PASSWORD = "apps/paperless/app/admin_password";
        PAPERLESS_SECRET_KEY = "apps/paperless/app/secret_key";
      };
      user = "";  # the image support non-root container by default
    };

    db = svc.db {
      user = dbUser;
      database = dbName;
    };

    redis = svc.container {
      id = 4;
      internet = false;
      image = "docker.io/library/redis:7.4.12";
      mounts = [ "/data" ];
    };

    paperllama = svc.container {
      id = 5;
      internet = false;
      image = "ghcr.io/tomasinjo/paper-llama:0.1.2";
      mounts = [ "prompt.txt:/app/prompt.txt" ];
      environment = {
        PAPERLESS_URL = "http://${svc.containerName "app"}:8000";
        OLLAMA_URL = "http://10.0.27.2:11434";
        OLLAMA_MODEL = "qwen3.8:27b-262k";
        SCAN_INTERVAL = "3600";
        OVERRIDE_EXISTING_TAGS = "True";
        LOG_LEVEL = "INFO";
        OCR_SOURCE = "llm";  # llm or paperless
        LLM_OCR_SOURCE_PAGE_LIMIT = "20"; # Applicable when "OCR_SOURCE=llm". If document has more pages, paperless OCR will be used
      };
      secrets = {
        PAPERLESS_TOKEN = "apps/paperless/app/api_key";
      };
      cmd = ["python" "main.py" "--mode" "auto"];
    };
  }