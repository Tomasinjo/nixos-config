{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../../modules/docker/oci-framework.nix { inherit lib config vars; };

  serviceName = "jellyfin";
  serviceHostname = "jelly";
  servicePort = 8096;

  containerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.web.exposed_gatekeeper { inherit serviceHostname servicePort; })
    oci-framework.hardware.quicksync
    {
      image = "jellyfin/jellyfin:10.11.6";

      environment = {
        "JELLYFIN_PublishedServerUrl" = "https://${serviceHostname}.${vars.networking.domain}";
      };

      volumes = [
        "${vars.dir.nixos_config}/apps/arrs/jellyfin/app-data:/config"
        "${vars.dir.nixos_config}/apps/arrs/jellyfin/app-cache:/cache"
        "${vars.dir.hoarder_data}/media:/media"
      ];

      ports = [];
      networks = [];
      
      labels = {
        "traefik.http.routers.${serviceHostname}.middlewares" = "jellyfin-mw,dynamic-whitelist@file"; # overwrites oci-framework
        "traefik.http.middlewares.jellyfin-mw.headers.customResponseHeaders.X-Robots-Tag" = "noindex,nofollow,nosnippet,noarchive,notranslate,noimageindex";
        "traefik.http.middlewares.jellyfin-mw.headers.STSSeconds" = "315360000";
        "traefik.http.middlewares.jellyfin-mw.headers.STSIncludeSubdomains" = "true";
        "traefik.http.middlewares.jellyfin-mw.headers.STSPreload" = "true";
        "traefik.http.middlewares.jellyfin-mw.headers.forceSTSHeader" = "true";
        "traefik.http.middlewares.jellyfin-mw.headers.frameDeny" = "true";
        "traefik.http.middlewares.jellyfin-mw.headers.contentTypeNosniff" = "true";
        "traefik.http.middlewares.jellyfin-mw.headers.customresponseheaders.X-XSS-PROTECTION" = "0";
        "traefik.http.middlewares.jellyfin-mw.headers.customFrameOptionsValue" = "allow-from https://${serviceHostname}.${vars.networking.domain}";
        "traefik.http.services.${serviceHostname}.loadBalancer.passHostHeader" = "true";
      };
    }
  ];

in {
  virtualisation.oci-containers.containers."${serviceName}-app" = containerConfig;
}