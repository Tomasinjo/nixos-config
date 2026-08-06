{ config, pkgs, lib, ... }:

# exposes gddr6-core-junction-vram-temps for checking VRAM temps

let
  gddr6-temps = pkgs.stdenv.mkDerivation rec {
    pname = "gddr6-core-junction-vram-temps";
    version = "2024-06-16";

    src = pkgs.fetchFromGitHub {
      owner = "ThomasBaruzier";
      repo = "gddr6-core-junction-vram-temps";
      rev = "main";
      sha256 = "sha256-dAAd4NuWnMfAKCVDuG9LFB5cVccDnH1csFrkGuOoO/M=";
    };

    nativeBuildInputs = with pkgs; [ gcc pkg-config ];

    buildInputs = with pkgs; [
      pciutils
      cudaPackages.cuda_nvml_dev
      config.hardware.nvidia.package
    ];

    # build environment
    preConfigure = ''
      export CUDA_PATH=${pkgs.cudaPackages.cuda_nvml_dev}
    '';

    # build
    buildPhase = ''
      runHook preBuild
      make
      runHook postBuild
    '';

    # install
    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      install -m 0755 gputemps $out/bin/gddr6-core-junction-vram-temps
      runHook postInstall
    '';
  };

in {
  environment.systemPackages = [ gddr6-temps ];
}
