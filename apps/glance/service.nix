{ lib, config, pkgs, vars, ... }:

let
  oci = import ../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };
  svc = oci.service { name = "glance"; id = 17; dir = ./.; };

in
  svc.build {
    app = svc.container {
      web = { 
        host = "home";
        port = 8080; 
        expose = "internal";
      };
      internet = true;  # news, github 
      image = "glanceapp/glance:v0.8.7";
      mounts = [
        "config:/app/config"
        "assets:/app/assets"
      ];
      environment = {};
      secrets = {
        GITHUB_TOKEN = "ext/github_token";
      };
    };
  }