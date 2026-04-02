{ config, pkgs, ... }:

{
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;
    };
  };
  environment.systemPackages = [ pkgs.kitty.terminfo ];  # for hosts without kitty, but with ssh: this fixes weird char echoing
}
