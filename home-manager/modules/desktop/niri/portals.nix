{ config, lib, pkgs, ... }:

# this is needed for file dialogs and popups

{
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-wlr
    ];
    config = {
      niri = {
        default = [ "xdg-desktop-portal-wlr" "xdg-desktop-portal-gtk" ];
        "org.freedesktop.impl.portal.FileChooser" = [ "xdg-desktop-portal-gtk" ];
        "org.freedesktop.impl.portal.Screenshot" = [ "xdg-desktop-portal-wlr" ];
      };
    };
  };

  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
    iconTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
    font = {
      name = "DejaVu Sans";
      size = 11;
    };
    gtk4 = {
      theme = null;
      extraConfig = {
        gtk-application-prefer-dark-theme = true;
      };
    };
  };

  # Set GTK theme for xdg-desktop-portal-gtk
  home.sessionVariables.GTK_THEME = "Adwaita-dark";
}
