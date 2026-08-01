{ config, pkgs, ... }:

{
  imports = [
    ./packages.nix
    ../../modules/shell.nix
  ];
}