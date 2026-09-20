{ config, pkgs, vars, ... }:

{
  users.users.${vars.username} = {
    isNormalUser = true;
    description = vars.fullName;
    shell = pkgs.zsh;
    uid = 1000;
  };

  programs.zsh.enable = true;

  # log interactive commands to journald (ships to VictoriaLogs on zenki;
  # lets the log-watch agent correlate error spikes with user actions)
  imports = [ ./command-history.nix ];
  services.command-history.enable = true;

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
