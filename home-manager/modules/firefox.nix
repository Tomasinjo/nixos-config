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

      # Check about:support for extension/add-on ID strings.
      # Valid strings for installation_mode are "allowed", "blocked",
      # "force_installed" and "normal_installed".
      ExtensionSettings = {
        "*".installation_mode = "blocked"; # blocks all addons except the ones specified below
        # uBlock Origin:
        "uBlock0@raymondhill.net" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          installation_mode = "force_installed";
        };
        # Bitwarden:
        "446900e4-71c2-419f-a6a7-df9c091e268b" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
          installation_mode = "force_installed";
        };
        # Dark Reader:
        "addon@darkreader.org" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/darkreader/latest.xpi";
          installation_mode = "force_installed";
        };
        # I still don't care about cookies:
        "idcac-pub@guus.ninja" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/istilldontcareaboutcookies/latest.xpi";
          installation_mode = "force_installed";
        };
        # Vimium:
        "{d7742d87-e61d-4b78-b8a1-b469842139fa}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/vimium-ff/latest.xpi";
          installation_mode = "force_installed";
        };
        # Dark space theme:
        "{22b0eca1-8c02-4c0d-a5d7-6604ddd9836e}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/nicothin-space/latest.xpi";
          installation_mode = "force_installed";
        };
        # Metamask:
        "webextension@metamask.io" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ether-metamask/latest.xpi";
          installation_mode = "force_installed";
        };
      };

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
              template = "https://search.${vars.networking.domain}/search?q={searchTerms}"; 
            }];
            icon = "https://search.${vars.networking.domain}/favicon.ico";
            updateInterval = 24 * 60 * 60 * 1000; # daily update
            definedAliases = [ "@s" ];
          };
        };
      };
    };
  };
}
