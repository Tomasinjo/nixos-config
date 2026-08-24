{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../../modules/docker/oci-framework.nix { inherit lib config pkgs vars; };

  serviceName = "comfyui";
  serviceHostname = "comfyui";
  servicePort = 8188;
  serviceId = 26;


  appContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.web.internal { inherit serviceHostname servicePort serviceName serviceId; })
    oci-framework.hardware.cuda
    {
      image = "yanwk/comfyui-boot:cu129-slim";

      environment = {
        "CLI_ARGS" = "--highvram";
      };

      volumes = [
        "${vars.dir.nixos_config}/apps/llm/comfyui/app-data:/root"
      ];

      networks = [
        "open-webui-net"
      ];

      user = ""; # does not support non-root
      autoStart = false;
    }
  ];


in {
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;
  systemd.services = oci-framework.mkNetwork { inherit serviceName serviceId; };
}
