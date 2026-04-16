{ pkgs, ... }: 
{
  programs.thunderbird = {
    enable = true;
    profiles = {
      my-profile = {
        isDefault = true;
        settings = {
          "extensions.activeThemeID" = "firefox-compact-dark@mozilla.org";
          "ui.systemUsesDarkTheme" = 1;
          # Ensure the content (emails) also tries to render in dark mode
          "layout.css.prefers-color-scheme.content-override" = 0; 
          "font.name.monospace.x-western" = "JetBrainsMono Nerd Font";
          "font.name.sans-serif.x-western" = "JetBrainsMono Nerd Font";
          "font.name.serif.x-western" = "JetBrainsMono Nerd Font";
        };
      };
    };
  };
}