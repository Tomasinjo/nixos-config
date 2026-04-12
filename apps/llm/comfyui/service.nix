{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../../modules/docker/oci-framework.nix { inherit lib config vars; };

  serviceName = "comfyui";
  serviceHostname = "comfyui";
  servicePort = 8188;


  appContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.web.internal { inherit serviceHostname servicePort serviceName; })
    oci-framework.hardware.cuda
    {
      image = "yanwk/comfyui-boot:cu129-slim";

      environment = {
        "CLI_ARGS" = "--highvram";
      };

      volumes = [
        "${vars.dir.nixos_config}/apps/llm/comfyui/app-data:/root"
      ];

      ports = [];

      networks = [
        "llm-net"
      ];
      
      labels = {};
      dependsOn = [];

      user = ""; # does not support non-root
      autoStart = false;
    }
  ];


in {
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;
}