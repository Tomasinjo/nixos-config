{ lib, config, pkgs, vars, ... }:

let
  oci = import ../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };
  svc = oci.service { name = "frigate"; id = 16; dir = ./.; };

in
  svc.build {
    app = svc.container {
      web = { 
        host = "nvr";
        port = 8971; 
        expose = "internal";
      };
      internet = false;
      image = "ghcr.io/blakeblackshear/frigate:0.18.2";
      mounts = [ "/config" ];
      extraMounts = [
        "${vars.dir.hoarder_data}/Recordings/:/media/frigate/"
      ];
      environment = {
        FRIGATE_MEDIA_DIR = "${vars.dir.hoarder_data}/Recordings/";
      };
      secrets = {
        FRIGATE_RTSP_USER = "apps/frigate/rtsp_user";
        FRIGATE_RTSP_PASSWORD = "apps/frigate/rtsp_password";
        FRIGATE_MQTT_USER = "apps/mqtt/user";
        FRIGATE_MQTT_PASSWORD = "apps/mqtt/password";
      };
      hardware = [ "quicksync" "coral" ];
      user = "";  # does not support nonroot
      capabilities = {
        "PERFMON" = true;
      };
      extraOptions = [
        "--shm-size=256m"
        "--tmpfs=/tmp/cache:rw,size=1G,mode=1777"
        "--cpuset-cpus=12-19"  # eco cores
      ];
      noNewPrivileges = false;  # wont start without it, says it cant access /run.
    };
  }