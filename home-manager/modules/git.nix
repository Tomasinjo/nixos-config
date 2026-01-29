{ config, lib, pkgs, ... }:

let
  secrets = import ../../secrets.nix;
in
{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Tomasinjo";
        email = secrets.email.tom;
      };
    };
  };
}
