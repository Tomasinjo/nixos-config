{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../../modules/docker/oci-framework.nix { inherit lib config vars; };

  serviceName = "";
  serviceHostname = "";
  servicePort = "";

  hugoContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    {
      image = "hugomods/hugo:exts-0.128.1";

      environment = {};

      volumes = [
        "${vars.dir.nixos_config}/apps/blog/web_server/app-data/src:/src"
        "${vars.dir.nixos_config}/apps/blog/web_server/app-data/cache:/tmp/hugo_cache"
      ];

      ports = [];
      networks = [];
      labels = {};
      
      autoStart = false;
      cmd = [ "hugo" "-s" "/src/${vars.apps.blog.si.name}" ];
    }
  ];

  containerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    {
      image = "joseluisq/static-web-server:2.41.0";

      environment = {
        "SERVER_CONFIG_FILE" = "/etc/config.toml";
      };

      volumes = [
        "${vars.dir.nixos_config}/apps/blog/web_server/app-data/src/${vars.apps.blog.si.name}/public:/var/www/${vars.apps.blog.si.name}/"
        "${vars.dir.nixos_config}/apps/blog/web_server/app-data/config.toml:/etc/config.toml"
      ];

      ports = [];

      networks = [ "traefik-net" ];
      
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.rp.rule" = "Host(`www.${vars.apps.blog.si.domain}`) || Host(`${vars.apps.blog.si.domain}`)";
        "traefik.http.routers.rp.entrypoints" = "https,http";
        "traefik.http.routers.rp.tls" = "true";
        "traefik.http.routers.rp.middlewares" = "umami@file,redirect-to-non-www-rp,security-headers";
        "traefik.http.routers.rp.tls.certresolver" = "fikus_resolver";

        "traefik.http.routers.ts.rule" = "Host(`www.${vars.apps.blog.en.domain}`) || Host(`${vars.apps.blog.en.domain}`)";
        "traefik.http.routers.ts.entrypoints" = "https,http";
        "traefik.http.routers.ts.tls" = "true";
        "traefik.http.routers.ts.middlewares" = "umami@file,redirect-to-non-www-ts,security-headers";
        "traefik.http.routers.ts.tls.certresolver" = "fikus_resolver";

        "traefik.http.middlewares.redirect-to-non-www-rp.redirectregex.regex" = "^https://www.${vars.apps.blog.si.domain}/(.*)";
        "traefik.http.middlewares.redirect-to-non-www-rp.redirectregex.replacement" = "https://${vars.apps.blog.si.domain}/$${1}";
        "traefik.http.middlewares.redirect-to-non-www-rp.redirectregex.permanent" = "true";
        "traefik.http.middlewares.redirect-to-non-www-ts.redirectregex.regex" = "^https://www.${vars.apps.blog.en.domain}/(.*)";
        "traefik.http.middlewares.redirect-to-non-www-ts.redirectregex.replacement" = "https://${vars.apps.blog.en.domain}/$${1}";
        "traefik.http.middlewares.redirect-to-non-www-ts.redirectregex.permanent" = "true";
      # "traefik.http.middlewares.security-headers.headers.contentSecurityPolicy" = "default-src 'self'; img-src 'self' blob:; script-src 'self' 'sha256-tfVx0w9y8hvPUv2efqvyLhKkrTZH8vGS3j+CsZ96foI" = "' 'sha256-rsY9H1ThvmzMVUqPsgUedBQu+YTa3N5/kjSNbXTJRuc" = "' 'sha256-yiWxoAmzJURraPf+3/ppalaG7yj64otd+LiwYbyQCcU" = "' 'sha256-kWffWXtHtJTDJ8ss3nKecVBOXFSsQCoSHOOzVtySPq4" = "' 'sha256-GiBI2nevdp8WU/sgymptDKGa4rg6KqQJCcNzJNQtfn0" = "' 'sha256-iJ/GoRMz19QIOL+oh3BfkRzsDtxdQVJp1Cnth0zK4/0" = "' 'sha256-E06Qmr9iPjms98E5rcn9fuXEi32gWdKISlZeLIRHx/s" = "'; style-src 'self' 'sha256-VjLI/Fbd1UuIo6DqMDZevsReuASBgjfW51jfgYstnmA" = "' 'sha256-47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU" = "' 'sha256-PjBkwE8xcYZAp+HsnzzOVNqa/Ra+/v1Fnx6f0PW6ic4" = "';";
        "traefik.http.middlewares.security-headers.headers.stsSeconds" = "31536000";
        "traefik.http.middlewares.security-headers.headers.stsIncludeSubdomains" = "true";
        "traefik.http.middlewares.security-headers.headers.stsPreload" = "true";
        "traefik.http.middlewares.security-headers.headers.forceSTSHeader" = "true";
        "traefik.http.middlewares.security-headers.headers.frameDeny" = "true";
        "traefik.http.middlewares.security-headers.headers.sslRedirect" = "true";
        "traefik.http.middlewares.security-headers.headers.browserXssFilter" = "true";
        "traefik.http.middlewares.security-headers.headers.contentTypeNosniff" = "true";
        "traefik.http.middlewares.security-headers.headers.referrerPolicy" = "same-origin";
      };
    }
  ];

in {
  virtualisation.oci-containers.containers."web-server-blog" = containerConfig;
  virtualisation.oci-containers.containers."hugo-papermodx" = hugoContainerConfig;
}