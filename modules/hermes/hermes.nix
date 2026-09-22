{ config, pkgs, vars, ... }:

{
  services.hermes-agent = {
    enable = true;

    backend = {
      mode = "dashboard";
      port = 9119;
      host = "0.0.0.0";
    };

    # managed as file
    configFile = ./config.yaml;

    environment = {
      GLM_API_KEY = vars.apps.hermes.app.glm;
      TELEGRAM_BOT_TOKEN = vars.apps.hermes.app.telegram_bot_token;
      TELEGRAM_ALLOWED_USERS = vars.apps.hermes.app.telegram_allowed_users;
    };

    # hermes CLI to PATH
    addToSystemPackages = true;

    # for telegram
    extraDependencyGroups = [ "messaging" ];
  };
}