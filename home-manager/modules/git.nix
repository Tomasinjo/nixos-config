{ config, lib, pkgs, vars, ... }:

{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Tomasinjo";
        email = vars.email.tom;
      };
      push = {
        autoSetupRemote = true;
      };
    };
  };
}
