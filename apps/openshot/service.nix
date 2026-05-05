{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../modules/docker/oci-framework.nix { inherit lib config vars; };

  serviceName = "openshot";
  serviceHostname = "openshot";
  servicePort = 3000;


  appContainerConfig = oci-framework.mergeAll [
    oci-framework.base.linuxserver
    (oci-framework.web.internal { inherit serviceHostname servicePort serviceName; })
    oci-framework.hardware.quicksync
    {
      image = "lscr.io/linuxserver/openshot:v3.5.1-ls66";

      environment = {
        "PIXELFLUX_WAYLAND" = "true";
        "DRINODE" = "/dev/dri/renderD128";
        "DRI_NODE" = "/dev/dri/renderD128";
      };

      volumes = [
        "${vars.dir.nixos_config}/apps/openshot/app-data:/config"
      ];

      ports = [];

      networks = [];
      
      labels = {};
      dependsOn = [];
      #dependsOn = [ "${serviceName}-db" ];  # DO NOT USE IT - backup will stop the db service and with it the dependency, which will not be restarted afterwards.

      # optional and overrides
      #entrypoint = "/example.sh";
      #user = "";

      #removeExtraOptions = [ "--security-opt=no-new-privileges:true" ];

      #extraOptions = [
      #  "--security-opt=no-new-privileges:false" # override the base compose - wont start without it, says it cant access /r
      #  "--tmpfs=/dev/shm:mode=770,uid=1111,gid=1111,size=268435456"
      #  "--tmpfs=/tmp/cache:mode=770,uid=1111,gid=1111,size=1G"
      #  "--cpuset-cpus=12-19"  # eco cores
      #];

      # use for rarely used service, systemd service must be manually started:
      # autoStart = false;

      # same as "command" compose directive
      #cmd = [
      #  "-loglevel=info"
      #  "-allowfrom=traefik"
      #];

      # FQDN: ${serviceHostname}.${vars.net.domain}
      # IP ${vars.net.zenki.common-vlan.ipv4Address}
    }
  ];


in {
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;
}