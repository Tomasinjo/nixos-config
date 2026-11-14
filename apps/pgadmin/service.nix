{ lib, config, pkgs, vars, ... }:

let
  oci = import ../../modules/podman/oci-framework.nix { inherit lib config pkgs vars; };
  svc = oci.service { name = "pgadmin"; id = 31; dir = ./.; };

in
  svc.build {
    app = svc.container {
      web = { 
        host = "pg";
        port = 80; 
        expose = "internal";
      };
      internet = false;
      image = "dpage/pgadmin4:9.19";
      mounts = [ "/var/lib/pgadmin" ];
      environment = {
        MFA_ENABLED = "false";
        PGADMIN_DEFAULT_EMAIL = vars.email.tom;
      };
      secrets = {
        PGADMIN_DEFAULT_PASSWORD = "apps/pgadmin/app/password";
      };
      user = "";  # does not support changing uids, runs with uid 5050
      noNewPrivileges = false;
    };
  }