{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../modules/docker/oci-framework.nix { inherit lib config vars; };

  serviceName = "";
  serviceHostname = "";
  servicePort = ;

  dbUser = "";
  dbPass = vars.apps.;
  dbName = "";

  appContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    #oci-framework.base.linuxserver
    #(oci-framework.web.base { inherit serviceHostname servicePort; })
    (oci-framework.web.internal { inherit serviceHostname servicePort; })
    #(oci-framework.web.exposed_gatekeeper { inherit serviceHostname servicePort; })
    #(oci-framework.web.exposed_mtls { inherit serviceHostname servicePort; })
    #oci-framework.hardware.cuda
    #oci-framework.hardware.quicksync
    {
      image = "";

      environment = {};

      volumes = [
        "${vars.dir.nixos_config}/apps/xxx/app-data:"
      ];

      ports = [];

      networks = [
        "arr-net"
        "ha-net"
        "fafi-net"
        "llm-net"
        "macvlan-10"
      ];
      
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

      # FQDN: ${serviceHostname}.${vars.net.domain}
      # IP ${vars.net.zenki.common-vlan.ipv4Address}
    }
  ];

  dbContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.apps.postgres { inherit dbUser dbPass dbName; })
    {
      volumes = [
        "${vars.dir.nixos_config}/apps/xxxx/db-data:/data/postgres"
      ];

      networks = [

      ];
    }
  ];

in {
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;
  virtualisation.oci-containers.containers."${serviceName}-db" = dbContainerConfig;
}