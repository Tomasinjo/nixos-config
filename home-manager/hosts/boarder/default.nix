{ config, pkgs, inputs, ... }:

{
  imports = [
    ./packages.nix
    ../../modules/shell.nix
  ];
}