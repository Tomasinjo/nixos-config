{ lib, config, pkgs, vars, ... }:

let
  oci = import ../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };
  svc = oci.service { name = "dockerproxy"; id = 47; dir = ./.; };

in
  svc.build {
    app = svc.container {
      image = "wollomatic/socket-proxy:1.13.2";
      extraMounts = [ "/var/run/docker.sock:/var/run/docker.sock:ro" ];
      user = "0:0";  # run as root so it can read the socket
      extraOptions = [
        "--read-only"
        "--memory=64M"
        "--cap-drop=ALL"
      ];
      cmd = [
        "-loglevel=INFO"
        "-allowfrom=10.0.1.2/32,10.0.17.2/32" # traefik, dockerproxy, doesnt really matter because it is also limited in nftables
        "-listenip=0.0.0.0"
        "-allowGET=/(v1\..{1,2}/)?(version|containers/.*|events.*)"  # this regexp allows readonly access only for requests from traefik and glance 
        "-allowHEAD=/_ping"
        "-shutdowngracetime=5"
        "-watchdoginterval=600"
        "-stoponwatchdog"
      ];
    };
  }