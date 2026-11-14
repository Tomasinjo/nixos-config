{ lib, config, pkgs, vars, ... }:

let
  oci = import ../../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };
  svc = oci.service { name = "ollama"; id = 27; dir = ./.; };

in
  svc.build {
    app = svc.container {
      internet = true;  # model pull
      image = "ollama/ollama:0.40.16";
      mounts = [ "/root/.ollama" ];
      environment = {
        OLLAMA_KEEP_ALIVE = "1h";
        OLLAMA_DEBUG = "0";
        OLLAMA_FLASH_ATTENTION = "1";
        OLLAMA_KV_CACHE_TYPE = "q4_0";
      };
      secrets = {};
      hardware = [ "cuda" ];
      user = "";  # does not support non-root
    };
  }