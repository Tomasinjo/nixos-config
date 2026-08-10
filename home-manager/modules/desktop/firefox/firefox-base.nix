{ pkgs, vars, config, ... }:

{
  programs.firefox = {
    enable = true;
    configPath = "${config.xdg.configHome}/mozilla/firefox";

    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      EnableTrackingProtection = {
        Value= true;
        Locked = true;
        Cryptomining = true;
        Fingerprinting = true;
      };
      DisablePocket = true;
      DisableFirefoxAccounts = true;
      DisableAccounts = true;
      DisableFirefoxScreenshots = true;
      OverrideFirstRunPage = "";
      OverridePostUpdatePage = "";
      DontCheckDefaultBrowser = true;
      DisplayBookmarksToolbar = "always";
      DisplayMenuBar = "default-off"; 
      SearchBar = "unified";
      DisableFirefoxSync = true;
      PasswordManagerEnabled = false;
      DisableFirefoxVPN = true;
    };

    profiles.myprofile = {
      settings = {
        "signon.rememberSignons" = false;
        "signon.autofillForms" = false;
        "signon.generation.enabled" = false;
        "sidebar.verticalTabs" = true;
        "browser.aboutConfig.showWarning" = false;
        "browser.download.useDownloadDir" = false;
        "browser.toolbars.bookmarks.visibility" = true;
        "browser.translations.neverTranslateLanguages" = "sl";
        "devtools.toolbox.host" = "right";
	      "browser.startup.homepage" = "https://home.${vars.net.domain}";
        "browser.contentblocking.category" = "strict";
        "media.peerconnection.enabled" = false;
        "media.navigator.enabled" = false;
        "media.peerconnection.ice.no_host" = true;
        "app.shield.optoutstudies.enabled" = false;
        "browser.crashReports.unsubmittedCheck.autoSubmit2" = false;
        "extensions.pocket.enabled" = false;
        "identity.fxaccounts.enabled" = false;
        "browser.cache.disk.enable" = true;
        "browser.cache.disk.smart_size.enabled" = true;
        "browser.cache.disk.capacity" = 1048576;  # 1GB
        "general.smoothScroll" = true;

      };
      search = {
        force = true;
        default = "Fikus";
        engines = {
          "Fikus" = {
            urls = [{ 
              template = "https://search.${vars.net.domain}/search?q={searchTerms}"; 
            }];
            icon = "https://search.${vars.net.domain}/favicon.ico";
            updateInterval = 24 * 60 * 60 * 1000; # daily update
            definedAliases = [ "@s" ];
          };
        };
      };
    };
  };
}
