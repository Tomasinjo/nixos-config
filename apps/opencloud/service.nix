{ lib, config, pkgs, vars, ... }:

let
  oci-framework = import ../../modules/docker/oci-framework.nix { inherit lib config vars; };

  serviceName = "opencloud";
  serviceHostname = "files";
  servicePort = 9200;

  appContainerConfig = oci-framework.mergeAll [
    oci-framework.base.standard
    (oci-framework.web.exposed_gatekeeper { inherit serviceHostname servicePort; })
    {
      image = "opencloudeu/opencloud-rolling:5.2.0";

      environment = {
        "OC_ADD_RUN_SERVICES" = ""; # enable stuff like antivirus, webdav, see docs
        "OC_URL" = "https://${serviceHostname}.${vars.net.domain}";
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
      };

      volumes = [
        "${vars.dir.nixos_config}/apps/opencloud/app-data:/etc/opencloud"
        "${vars.dir.nixos_config}/apps/opencloud/app-apps:/var/lib/opencloud/web/assets/apps"
        "${vars.dir.impo_data}/opencloud:/var/lib/opencloud"
      ];

      ports = [];
      networks = [];
      labels = {

        "traefik.http.routers.opencloud-share.rule" = "Host(`${serviceHostname}.${vars.net.domain}`) && PathRegexp(`^\/s\/(?:[A-Z,a-z,0-9]){15}$`)";
        "traefik.http.routers.opencloud-share.entrypoints" = "https,http";
        "traefik.http.routers.opencloud-share.tls" = "true";
<<<<<<< HEAD
        "traefik.http.routers.opencloud-share.tls.certresolver" = "fikus_resolver";
=======
>>>>>>> d77319e9b9a8b8dc87a973320b35076d0602b5dc
        "traefik.http.routers.opencloud-share.middlewares" = "gatekeeper_opencloud_share@docker";
      };
      dependsOn = [];

      entrypoint = "/bin/sh";
      cmd = [ "-c" "opencloud init || true; opencloud server" ];
    }
  ];

in {
  virtualisation.oci-containers.containers."${serviceName}-app" = appContainerConfig;
}