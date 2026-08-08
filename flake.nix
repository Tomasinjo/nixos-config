{
  description = "Zenki Home Server & Gaming Rig, Lenko Laptop";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixvim.url = "github:nix-community/nixvim/nixos-26.05";
    nur.url = "github:nix-community/NUR";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    yazi.url = "github:sxyazi/yazi";
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.1.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixvim, nur, home-manager, yazi, lanzaboote, ... }@inputs: let
    vars = import ./vars.nix;
  in {
    nixosConfigurations = {
      zenki = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs vars self; };
        modules = [
          ./hosts/zenki/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.sharedModules = [ nixvim.homeManagerModules.nixvim ];
            home-manager.users.tom = ./home-manager/users/tom.nix;
            home-manager.extraSpecialArgs = { inherit inputs vars; hostName = "zenki"; };
          }
        ];
      };

      lenko = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs vars self; };
        modules = [
          ./hosts/lenko/configuration.nix
          home-manager.nixosModules.home-manager
          nur.modules.nixos.default
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.sharedModules = [ nixvim.homeModules.nixvim ];
            home-manager.users.tom = ./home-manager/users/tom.nix;
            home-manager.extraSpecialArgs = { inherit inputs vars; hostName = "lenko"; };
          }
          lanzaboote.nixosModules.lanzaboote
          ({ pkgs, lib, ... }: {

            # lanzaboote replaces systemd-boot, the following ensures it is disabled even though the host config might have boot.loader.systemd-boot.enable set to true
            boot.loader.systemd-boot.enable = lib.mkForce false;
            
            boot.lanzaboote = {
              enable = true;
              pkiBundle = "/var/lib/sbctl";
            };
          })
        ];
      };


      sensei = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs vars self; };
        modules = [
          ./hosts/sensei/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.sharedModules = [ nixvim.homeManagerModules.nixvim ];
            home-manager.users.tom = ./home-manager/users/tom.nix;
            home-manager.extraSpecialArgs = { inherit inputs vars; hostName = "sensei"; };
          }
        ];
      };

      boarder = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs vars self; };
        modules = [
          ./hosts/boarder/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.sharedModules = [ nixvim.homeManagerModules.nixvim ];
            home-manager.users.tom = ./home-manager/users/tom.nix;
            home-manager.extraSpecialArgs = { inherit inputs vars; hostName = "boarder"; };
          }
        ];
      };
    };
  };
}
