{ lib, config, pkgs, inputs, vars, ... }:

let
  # Access zenki's fully evaluated configuration from your flake inputs
  zenkiConfig = inputs.self.nixosConfigurations.zenki.config;
  
  zenkiContainers = zenkiConfig.virtualisation.oci-containers.containers;

  webServices = lib.filterAttrs (name: container: 
    (container.labels."traefik.enable" or "false") == "true"
  ) zenkiContainers;

  bookmarksList = lib.mapAttrsToList (name: container: 
    let
      # take a hostname and service name from custom docker labels
      hostName = container.labels."fikus.hostname" or (builtins.head (lib.splitString "-" name));
      serviceName = container.labels."fikus.name" or (builtins.head (lib.splitString "-" name));
      
      # prettyfies the service name, replace - with space and capitalizes
      prettyName = lib.concatStringsSep " " (map (s: (lib.toUpper (builtins.substring 0 1 s)) + (builtins.substring 1 (-1) s)) (lib.splitString " " (builtins.replaceStrings ["-"] [" "] serviceName)));
    in {
      name = prettyName;
      url = "https://${hostName}.${vars.net.domain}";
    }
  ) webServices;

in {
  programs.firefox = {
    profiles.myprofile.bookmarks = {
      force = true;
      settings = [
        {
          name = "Zenki Services";
          toolbar = true;
          bookmarks = [
            {
              name = "Services"; 
              bookmarks = bookmarksList;
            }
          ];
        }
      ];
    };
  };
}