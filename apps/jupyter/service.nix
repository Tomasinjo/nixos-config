{ lib, config, pkgs, vars, ... }:

let
  oci = import ../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };
  svc = oci.service { name = "jupyter"; id = 24; dir = ./.; };

in
  svc.build {
    app = svc.container {
      web = { 
        host = "jupyter";
        port = 8888; 
        expose = "internal";
      };
      internet = true;  # dependency downloads? not sure
      image = "quay.io/jupyter/scipy-notebook:x86_64-notebook-7.0.6";
      mounts = [ "/home/jovyan" ];
      extraMounts = [
        "${pkgs.writeText "install-reqs.sh" ''
          #!/bin/bash
          pip install --user --no-cache-dir -r /home/jovyan/requirements.txt
        ''}:/usr/local/bin/before-notebook.d/install-reqs.sh:ro"
      ];
      extraOptions = [
        "--cpuset-cpus=12-19"  # eco cores
      ];
    };
  }