{ config, pkgs, vars, ... }:

{
  users.users.${vars.username} = {
    isNormalUser = true;
    description = vars.fullName;
    shell = pkgs.zsh;
    uid = 1000;
  };

  programs.zsh.enable = true;

  # Shell command audit log, written by the home-manager zsh config and read by modules/vector.nix
  users.groups.vector = { };
  systemd.tmpfiles.rules = [
    "d /var/log/zsh 0750 ${vars.username} vector -"
    "a+ /var/log/zsh - - - - default:g:vector:r-x" # files created by zsh stay readable by vector regardless of umask
  ];

  time.timeZone = vars.timeZone;
  i18n.defaultLocale = "en_US.UTF-8";

  services.xserver.xkb = {
    layout = "us";
    model = "pc105"; 
  };

  nix.gc = {   # delete old generations
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true; # Saves space by de-duplicating files
    download-buffer-size = 524288000; # 500mb
  };
  nixpkgs.config.allowUnfree = true;
}
