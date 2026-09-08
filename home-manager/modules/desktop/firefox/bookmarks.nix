{ lib, config, pkgs, inputs, vars, ... }:

let
  getContainers = import ../../../../helpers/get-containers.nix { inherit inputs lib; };
  webServices = getContainers {
    filter = (name: container: container.labels ? "glance.name" && container.labels ? "glance.url");
  };

  bookmarksList = lib.mapAttrsToList (name: container: 
    {
      name = container.labels."glance.name";
      url = container.labels."glance.url";
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