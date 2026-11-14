{ lib, config, pkgs, vars, ... }:

let
  oci = import ../../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };
  svc = oci.service { name = "jellyfin"; id = 33; dir = ./.; };

  hostname = "jelly";
in
  svc.build {
    app = svc.container {
      web = { 
        host = hostname;
        port = 8096; 
        expose = "gatekeeper";
      };
      internet = true; # imdb
      image = "jellyfin/jellyfin:12.4";
      mounts = [
        "config:/config"
        "cache:/cache"
      ];
      extraMounts = [
        "${vars.dir.hoarder_data}/media:/media"
      ];
      environment = {
        JELLYFIN_PublishedServerUrl = "https://${hostname}.${vars.net.domain}";
      };
      labels = {
        "traefik.http.routers.${hostname}.middlewares" = "jellyfin-mw,dynamic-whitelist@file"; # overwrites oci-framework
        "traefik.http.middlewares.jellyfin-mw.headers.customResponseHeaders.X-Robots-Tag" = "noindex,nofollow,nosnippet,noarchive,notranslate,noimageindex";
        "traefik.http.middlewares.jellyfin-mw.headers.STSSeconds" = "315360000";
        "traefik.http.middlewares.jellyfin-mw.headers.STSIncludeSubdomains" = "true";
        "traefik.http.middlewares.jellyfin-mw.headers.STSPreload" = "true";
        "traefik.http.middlewares.jellyfin-mw.headers.forceSTSHeader" = "true";
        "traefik.http.middlewares.jellyfin-mw.headers.frameDeny" = "true";
        "traefik.http.middlewares.jellyfin-mw.headers.contentTypeNosniff" = "true";
        "traefik.http.middlewares.jellyfin-mw.headers.customresponseheaders.X-XSS-PROTECTION" = "0";
        "traefik.http.middlewares.jellyfin-mw.headers.customFrameOptionsValue" = "allow-from https://${hostname}.${vars.net.domain}";
        "traefik.http.services.${hostname}.loadBalancer.passHostHeader" = "true";
      };
      hardware = [ "quicksync" ];
    };
  }