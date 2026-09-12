{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };

  serviceName = "piped";
  serviceHostname = "youtube";
  servicePort = 80;

  backendServiceHostame = "youtube-backend";
  backendServicePort = 8080;

  proxyServiceHostame = "youtube-proxy";
  proxyServicePort = 8080;
  
  serviceId = 41;
  
  dbUser = "piped";
  dbPass = vars.apps.piped.db.password;
  dbName = "piped";

  frontendContainerConfig = oci-framework.mergeAll [
    (oci-framework.web.exposed_gatekeeper { 
      inherit serviceName serviceId serviceHostname servicePort; 
    })
    {
      image = "1337kavin/piped-frontend:latest";

      environment = {
        "BACKEND_HOSTNAME" = "${backendServiceHostame}.${vars.net.domain}";
        "HTTP_MODE" = "https";
      };

      user = ""; # nginx permission denied if not root

      extraOptions = [
        "--sysctl=net.ipv4.ip_unprivileged_port_start=0" # allows binding low ports, nginx uses 80 in container
      ];
    }
  ];

  dbContainerConfig = oci-framework.mergeAll [
    (oci-framework.apps.postgres { inherit serviceName serviceId dbUser dbPass dbName; })
    {
      volumes = [
        "${vars.dir.nixos_config}/apps/piped/db-data:/data/postgres"
      ];
    }
  ];

  backendContainerConfig = oci-framework.mergeAll [
    (oci-framework.web.exposed_gatekeeper {  
      inherit serviceName serviceId;
      serviceHostname = backendServiceHostame;
      servicePort = backendServicePort;
      containerId = 4; # Override containerId to avoid collision with app
      requiresInternet = "true";
    })
    {
      image = "1337kavin/piped:latest";

      volumes = [
        "${vars.dir.nixos_config}/apps/piped/backend-data/config.properties:/app/config.properties:ro"
      ];

      labels = {
        "glance.hide" = "true";
      };
    }
  ];


  proxyContainerConfig = oci-framework.mergeAll [
    (oci-framework.web.exposed_gatekeeper {  
      inherit serviceName serviceId;
      serviceHostname = proxyServiceHostame;
      servicePort = proxyServicePort;
      containerId = 5; # Override containerId to avoid collision with app
      requiresInternet = "true";
    })
    {
      image = "1337kavin/piped-proxy:latest";

      labels = {
        "glance.hide" = "true";
      };
    }
  ];

  bgHelperContainerConfig = oci-framework.mergeAll [
    (oci-framework.core {
      inherit serviceName serviceId; containerId = 6;
      requiresInternet = "true";
    })
    {
      image = "1337kavin/bg-helper-server:latest";
    }
  ];

in {
  virtualisation.oci-containers.containers."${serviceName}-frontend" = frontendContainerConfig;
  virtualisation.oci-containers.containers."${serviceName}-db" = dbContainerConfig;
  virtualisation.oci-containers.containers."${serviceName}-backend" = backendContainerConfig;
  virtualisation.oci-containers.containers."${serviceName}-proxy" = proxyContainerConfig;
  virtualisation.oci-containers.containers."${serviceName}-bghelper" = bgHelperContainerConfig;

  systemd.services = oci-framework.mkNetwork { inherit serviceName serviceId; };
}
