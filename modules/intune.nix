{ pkgs, ... }:

{
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;
  services.intune.enable = true;
  environment.systemPackages = with pkgs; [
    microsoft-edge
  ];
}
