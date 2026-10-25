{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };

  serviceName = "comfyui";
  serviceHostname = "comfyui";
  servicePort = 8188;
  serviceId = 26;


  appContainerConfig = oci-framework.mergeAll [
    (oci-framework.web.internal { inherit serviceName serviceId serviceHostname servicePort; })
    oci-framework.hardware.cuda
    {
      image = "yanwk/comfyui-boot:cu130-slim-v2-20261016";

      environment = {
        "CLI_ARGS" = "";
      };

      volumes = [
        "${vars.dir.nixos_config}/apps/llm/comfyui/app-data/storage-cache/dot-cache:/root/.cache"
        "${vars.dir.nixos_config}/apps/llm/comfyui/app-data/storage-cache/dot-config:/root/.config"
        "${vars.dir.nixos_config}/apps/llm/comfyui/app-data/storage-nodes/dot-local:/root/.local"
        "${vars.dir.nixos_config}/apps/llm/comfyui/app-data/storage-nodes/custom_nodes:/root/ComfyUI/custom_nodes"
        "${vars.dir.nixos_config}/apps/llm/comfyui/app-data/storage-models/models:/root/ComfyUI/models"
        "${vars.dir.nixos_config}/apps/llm/comfyui/app-data/storage-models/hf-hub:/root/.cache/huggingface/hub"
        "${vars.dir.nixos_config}/apps/llm/comfyui/app-data/storage-models/torch-hub:/root/.cache/torch/hub"
        "${vars.dir.nixos_config}/apps/llm/comfyui/app-data/storage-user/input:/root/ComfyUI/input"
        "${vars.dir.nixos_config}/apps/llm/comfyui/app-data/storage-user/output:/root/ComfyUI/output"
        "${vars.dir.nixos_config}/apps/llm/comfyui/app-data/storage-user/user-profile:/root/ComfyUI/user"
        "${vars.dir.nixos_config}/apps/llm/comfyui/app-data/storage-user/user-scripts:/root/user-scripts"
      ];

      user = ""; # does not support non-root
      autoStart = false;
    }
  ];


in {
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;
  systemd.services = oci-framework.mkNetwork { inherit serviceName serviceId; };
}
