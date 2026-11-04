{ config, pkgs, lib, ... }:

# exposes gddr6 for checking VRAM temps
# eventual replacement for gddr6-temps.nix
# run with: sudo gddr6 (needs iomem=relaxed, already set in init.nix)

let
  gddr6 = pkgs.stdenv.mkDerivation rec {
    pname = "gddr6";
    version = "2026-09-19";

    src = pkgs.fetchFromGitHub {
      owner = "olealgoritme";
      repo = "gddr6";
      rev = "586c77ac61ae06a2992bc8e86b9def95c8151e96";
      sha256 = "sha256-xUY9TdsZJ3zyFv1F/4GBcY2i7urozghaSnJM+UdGkrY=";
    };

    nativeBuildInputs = with pkgs; [ cmake ];
    buildInputs = with pkgs; [ pciutils ];
  };

in {
  environment.systemPackages = [ gddr6 ];
}
