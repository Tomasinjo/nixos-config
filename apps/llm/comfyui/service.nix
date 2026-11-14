{ lib, config, pkgs, vars, ... }:

let
  oci = import ../../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };
  svc = oci.service { name = "comfyui"; id = 26; dir = ./.; };

in
  svc.build {
    app = svc.container {
      web = { 
        host = "comfyui";
        port = 8188; 
        expose = "internal";
      };
      internet = true;
      image = "yanwk/comfyui-boot:cu130-slim-v2-20261016";
      mounts = [
        "storage-cache/dot-cache:/root/.cache"
        "storage-cache/dot-config:/root/.config"
        "storage-nodes/dot-local:/root/.local"
        "storage-nodes/custom_nodes:/root/ComfyUI/custom_nodes"
        "storage-models/models:/root/ComfyUI/models"
        "storage-models/hf-hub:/root/.cache/huggingface/hub"
        "storage-models/torch-hub:/root/.cache/torch/hub"
        "storage-user/input:/root/ComfyUI/input"
        "storage-user/output:/root/ComfyUI/output"
        "storage-user/user-profile:/root/ComfyUI/user"
        "storage-user/user-scripts:/root/user-scripts"
      ];
      environment = {
        CLI_ARGS = "";
      };
      user = ""; # does not support non-root
      autoStart = false;
      hardware = [ "cuda" ];
    };
  }