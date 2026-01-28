{ config, lib, pkgs, ... }:

{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Tom";
        email = "tom@fikus";
      };
    };
  };
}
