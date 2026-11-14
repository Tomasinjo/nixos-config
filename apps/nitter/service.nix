{ lib, config, pkgs, vars, ... }:

let
  oci = import ../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };
  svc = oci.service { name = "nitter"; id = 38; dir = ./.; };

in
  svc.build {
    app = svc.container {
      web = { 
        host = "x";
        port = 8080; 
        expose = "gatekeeper";
      };
      internet = true;  # fetching from twitter
      image = "zedeus/nitter:latest";  # does not tag image!!
      mounts = [
        "nitter.conf:/src/nitter.conf"
        "sessions.jsonl:/src/sessions.jsonl"
      ];
    };

    redis = svc.container {
      id = 4;
      internet = false;
      image = "docker.io/library/redis:7.4.12";
      mounts = [ "/data" ];
    };
  }