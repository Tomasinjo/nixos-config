{ pkgs, vars, ... }:

{
  programs.firefox = {
    enable = true;

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
