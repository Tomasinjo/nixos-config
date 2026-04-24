{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../../modules/docker/oci-framework.nix { inherit lib config vars; };

  serviceName = "opencloud";
  serviceHostname = "files";
  servicePort = 9200;

  appContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.web.exposed_gatekeeper { inherit serviceHostname servicePort serviceName; })
    {
      image = "opencloudeu/opencloud-rolling:6.1.0";

      environment = {
        "OC_ADD_RUN_SERVICES" = "collaboration"; # enable stuff like antivirus, webdav, see docs
        "OC_URL" = "https://${serviceHostname}.${vars.net.domain}";
        "OC_JWT_SECRET" = vars.apps.opencloud.app.jwt_secret;
        "OC_LOG_LEVEL" = "info";
        "OC_LOG_COLOR" = "false";
        "OC_LOG_PRETTY" = "false";
        "PROXY_TLS" = "false";
        "OC_INSECURE" = "false";
        "PROXY_ENABLE_BASIC_AUTH" = "false"; # (not recommended, but needed for eg. WebDav clients that do not support OpenID Connect)
        "IDM_CREATE_DEMO_USERS" = "false";
        "IDM_ADMIN_PASSWORD" = vars.apps.opencloud.app.admin_password;
        # control the password enforcement and policy for public shares
        "OC_SHARING_PUBLIC_SHARE_MUST_HAVE_PASSWORD" = "false";
        "OC_SHARING_PUBLIC_WRITEABLE_SHARE_MUST_HAVE_PASSWORD" = "false";
        "OC_PASSWORD_POLICY_DISABLED" = "true";
        "OC_DEFAULT_LANGUAGE" = "en";
        # Onlyofice integration
        "COLLABORA_DOMAIN" = "office.${vars.net.domain}";
        "COLLABORATION_APP_NAME" = "OnlyOffice";
        "COLLABORATION_APP_PRODUCT" = "OnlyOffice";
        "COLLABORATION_APP_ADDR" = "https://office.${vars.net.domain}";
        "COLLABORATION_APP_INSECURE" = "false";
        "COLLABORATION_CS3API_DATAGATEWAY_INSECURE" = "false";
        "COLLABORATION_WOPI_SRC" = "http://${serviceName}-app:9300";
        "COLLABORATION_HTTP_ADDR" = "0.0.0.0:9300";
      };

      volumes = [
        "${vars.dir.nixos_config}/apps/cloud/opencloud/app-data:/etc/opencloud"
        "${vars.dir.nixos_config}/apps/cloud/opencloud/app-apps:/var/lib/opencloud/web/assets/apps"
        "${vars.dir.impo_data}/opencloud:/var/lib/opencloud"
      ];

      ports = [];
      networks = [
        "cloud-net"
      ];
      labels = {
        "traefik.http.middlewares.add-csp.headers.contentSecurityPolicy" = "frame-ancestors 'self' https://*.${vars.net.domain}"; # for onlyoffice to load as iframe. Docs suggest to use yaml to set CSP, but i was lazy https://docs.opencloud.eu/docs/dev/server/services/proxy/information#content-security-policy
        "traefik.http.routers.${serviceHostname}.middlewares" = "add-csp,dynamic-whitelist@file";  # added dynamic-whitelist@file here since it overwrites oci-framework settings
        "traefik.http.routers.opencloud-share.rule" = "Host(`${serviceHostname}.${vars.net.domain}`) && PathRegexp(`^\/s\/(?:[A-Z,a-z,0-9]){15}$`)";
        "traefik.http.routers.opencloud-share.entrypoints" = "https,http";
        "traefik.http.routers.opencloud-share.tls" = "true";
        "traefik.http.routers.opencloud-share.middlewares" = "gatekeeper_opencloud_share@docker,add-csp";
      };
      dependsOn = [];

      entrypoint = "/bin/sh";
      cmd = [ "-c" "opencloud init || true; opencloud server" ];
    }
  ];



  radicaleContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    {
      image = "opencloudeu/radicale:3.5.7";

      environment = {};

      volumes = [
        "${vars.dir.nixos_config}/apps/cloud/opencloud/radicale-data/config:/etc/radicale/config"
        "${vars.dir.nixos_config}/apps/cloud/opencloud/radicale-data/data:/var/lib/radicale"
      ];

      ports = [];

      networks = [
        "cloud-net"
      ];

      labels = {};
    }
  ];

in {
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;
  virtualisation.oci-containers.containers."radicale" = radicaleContainerConfig;
}