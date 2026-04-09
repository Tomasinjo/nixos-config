{ lib, config, pkgs, vars, ... }:


let
  oci-framework = import ../../../modules/docker/oci-framework.nix { inherit lib config vars; };

  serviceName = "onlyoffice";
  serviceHostname = "office";
  servicePort = 80;

  appContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.web.exposed_gatekeeper { inherit serviceHostname servicePort; })    {
      image = "onlyoffice/documentserver:9.3.1";

      environment = {
        "WOPI_ENABLED" = "true";
        "USE_UNAUTHORIZED_STORAGE" = "false";
        "JWT_ENABLED" = "true";
      };

      volumes = [];

      ports = [];

      networks = [
        "cloud-net"
      ];
      
      labels = {
        # when embeded in opencloud, one request is sent via http for some reason, making firefox to refuse to load due to mixed protocols
        # the following upgrades all connections to https
        # https://github.com/ONLYOFFICE/DocumentServer/issues/2186#issuecomment-3973424679
        "traefik.http.routers.${serviceHostname}.middlewares" = "onlyoffice-headers,dynamic-whitelist@file";  # added dynamic-whitelist@file here since it overwrites oci-framework settings
        "traefik.http.middlewares.onlyoffice-headers.headers.customrequestheaders.X-Forwarded-Proto" = "https";
        "traefik.http.middlewares.onlyoffice-headers.headers.customresponseheaders.Content-Security-Policy" = "upgrade-insecure-requests";
      };

      user = "";  # does not support non-root
    }
  ];


in {
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;
}