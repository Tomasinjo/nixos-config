{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../modules/docker/oci-framework.nix { inherit lib config vars; };

  serviceName = "frigate";
  serviceHostname = "nvr";
  servicePort = 8971;

  appContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.web.internal { inherit serviceHostname servicePort; })
    oci-framework.hardware.quicksync
    oci-framework.hardware.coral
    {
      image = "ghcr.io/blakeblackshear/frigate:0.17.0";

      environment = {
        "FRIGATE_RTSP_USER" = vars.apps.frigate.rtsp_user;
        "FRIGATE_RTSP_PASSWORD" = vars.apps.frigate.rtsp_password;
        "FRIGATE_MQTT_USER" = vars.apps.mqtt.user;
        "FRIGATE_MQTT_PASSWORD" = vars.apps.mqtt.password;
        "FRIGATE_MEDIA_DIR" = "${vars.dir.hoarder_data}/Recordings/";
      };

      volumes = [
        "${vars.dir.nixos_config}/apps/frigate/app-data:/config"
        "${vars.dir.hoarder_data}/Recordings/:/media/frigate/"

        # The following overrides are required to support running as a non-root user
        # s6 overrides
        "${vars.dir.nixos_config}/apps/frigate/overrides/s6/log-prepare-run:/etc/s6-overlay/s6-rc.d/log-prepare/run"
        "${vars.dir.nixos_config}/apps/frigate/overrides/s6/nginx-check:/etc/s6-overlay/s6-rc.d/nginx/data/check"
        "${vars.dir.nixos_config}/apps/frigate/overrides/s6/s6-applyuidgid:/package/admin/s6/command/s6-applyuidgid"

        # letsencrypt dirs need to exist so that we can provide certs or so that the container can generate self-signed certs and store them here
        "${vars.dir.nixos_config}/apps/frigate/overrides/letsencrypt/live/frigate:/etc/letsencrypt/live/frigate"
        "${vars.dir.nixos_config}/apps/frigate/overrides/letsencrypt/www:/etc/letsencrypt/www"

        # nginx overrides
        "${vars.dir.nixos_config}/apps/frigate/overrides/nginx/conf/nginx.conf:/usr/local/nginx/conf/nginx.conf"
        "${vars.dir.nixos_config}/apps/frigate/overrides/nginx/conf/base_path.conf:/usr/local/nginx/conf/base_path.conf"
        "${vars.dir.nixos_config}/apps/frigate/overrides/nginx/conf/listen.conf:/usr/local/nginx/conf/listen.conf"
        "${vars.dir.nixos_config}/apps/frigate/overrides/nginx/logs:/usr/local/nginx/logs"
        "${vars.dir.nixos_config}/apps/frigate/overrides/nginx/temp_dirs:/usr/local/nginx/temp_dirs"
      ];

      ports = [
        # "${vars.net.zenki.common-vlan.ipv4Address}:1935:1935" # RTMP feeds
        "${vars.net.zenki.common-vlan.ipv4Address}:8555:8555"
      ];

      networks = [
        "ha-net"
      ];
      
      labels = {};
      dependsOn = [];
      
      capabilities = {
        "PERFMON" = true;
      };
      removeExtraOptions = [ "--security-opt=no-new-privileges:true" ];

      extraOptions = [
        "--security-opt=no-new-privileges:false" # override the base compose - wont start without it, says it cant access /run.
        "--tmpfs=/dev/shm:mode=770,uid=1111,gid=1111,size=268435456"
        "--tmpfs=/tmp/cache:mode=770,uid=1111,gid=1111,size=1G"
        "--cpuset-cpus=12-19"  # eco cores
      ];
    }
  ];

in {
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;
}