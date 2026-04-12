{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../modules/docker/oci-framework.nix { inherit lib config vars; };

  serviceName = "jupyter";
  serviceHostname = "jupyter";
  servicePort = 8888;

  appContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.web.internal { inherit serviceHostname servicePort serviceName; })
    {
      image = "quay.io/jupyter/scipy-notebook:x86_64-notebook-7.0.6";

      environment = {};

      volumes = [
        "${vars.dir.nixos_config}/apps/jupyter/app-data:/home/jovyan"
        "${pkgs.writeText "install-reqs.sh" ''
          #!/bin/bash
          pip install --user --no-cache-dir -r /home/jovyan/requirements.txt
        ''}:/usr/local/bin/before-notebook.d/install-reqs.sh:ro"
      ];

      ports = [];

      networks = [
        "fafi-net"
      ];
      
      labels = {};
      dependsOn = [];

      extraOptions = [
        "--cpuset-cpus=12-19"  # eco cores
      ];
    }
  ];

in {
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;
}