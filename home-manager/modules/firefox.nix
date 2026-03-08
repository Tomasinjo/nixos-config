{ pkgs, vars, ... }:

{
  programs.firefox = {
    enable = true;
    profiles.myprofile = {
      settings = {
        "signon.rememberSignons" = false;
        "signon.autofillForms" = false;
        "signon.generation.enabled" = false;
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
      extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
	      ublock-origin
	      bitwarden
	      darkreader
	      vimium
      ];
    };
  };
}
