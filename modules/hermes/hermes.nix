{ config, pkgs, vars, ... }:

{
  services.hermes-agent = {
    enable = true;

    backend = {
      mode = "dashboard";
      port = 9119;
      host = "0.0.0.0";
    };

    # managed as file, copied to hermes home (/var/lib/hermes/.hermes/config.yaml) at every reload
    configFile = ./config.yaml;

    environment = {
      GLM_API_KEY = vars.apps.hermes.app.glm;
      TELEGRAM_BOT_TOKEN = vars.apps.hermes.app.telegram_bot_token;
      TELEGRAM_ALLOWED_USERS = vars.apps.hermes.app.telegram_allowed_users;
      HASS_URL = "http://10.0.22.2:8123";
      HASS_TOKEN = vars.apps.home-assistant.app.long_lived_token;
    };

    # hermes CLI to PATH
    addToSystemPackages = true;

    # for telegram
    extraDependencyGroups = [ "messaging" ];
    
  };

  system.activationScripts.hermesAcl = ''
    ${pkgs.acl}/bin/setfacl -m u:hermes:x /home/tom
    ${pkgs.acl}/bin/setfacl -m u:hermes:rX,d:u:hermes:rX -R /home/tom/nixos-config
    ${pkgs.acl}/bin/setfacl -m u:hermes:rwX -R /home/tom/nixos-config/apps/ha/home_assistant/ /home/tom/nixos-config/apps/ha/appdaemon/
    ${pkgs.acl}/bin/setfacl -b /home/tom/nixos-config/apps/traefik/app-data/certs/acme.json
    chmod 600 /home/tom/nixos-config/apps/traefik/app-data/certs/acme.json
  '';
}