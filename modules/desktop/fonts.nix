{ config, pkgs, inputs, vars, ... }:

{
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    font-awesome
  ];
}
