{
  description = "Zenki Home Server & Gaming Rig, Lenko Laptop";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixvim = {
      url = "github:nix-community/nixvim/nixos-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur.url = "github:nix-community/NUR";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixvim, nur, home-manager, ... }@inputs: let
    vars = import ./vars.nix;
  in {
    nixosConfigurations = {
      zenki = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs vars self; };
        modules = [
          ./hosts/zenki/configuration.nix
          nixvim.nixosModules.nixvim
          ./modules/nixvim.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
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
          nixvim.nixosModules.nixvim
          ./modules/nixvim.nix
          home-manager.nixosModules.home-manager
          nur.modules.nixos.default
         {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.tom = ./home-manager/users/tom.nix;
            home-manager.extraSpecialArgs = { inherit inputs vars; hostName = "lenko"; };
          }
        ];
      };

      sensei = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs vars self; };
        modules = [
          ./hosts/sensei/configuration.nix
          nixvim.nixosModules.nixvim
          ./modules/nixvim.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
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
          nixvim.nixosModules.nixvim
          ./modules/nixvim.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.tom = ./home-manager/users/tom.nix;
            home-manager.extraSpecialArgs = { inherit inputs vars; hostName = "boarder"; };
          }
        ];
      };
    };
  };
}
