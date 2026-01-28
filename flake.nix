{
  description = "Zenki Home Server & Gaming Rig, Lenko Laptop";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    hyprland.url = "github:hyprwm/Hyprland";
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur.url = "github:nix-community/NUR";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixvim, nur, home-manager, hyprland, ... }@inputs: {
    nixosConfigurations = {
      zenki = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/zenki/configuration.nix
          nixvim.nixosModules.nixvim
          ./modules/nixvim.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.tom = ./home-manager/users/tom.nix;
            home-manager.extraSpecialArgs = { inherit inputs hyprland; hostName = "zenki"; };
          }
        ];
      };

      lenko = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
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
            home-manager.extraSpecialArgs = { inherit inputs hyprland; hostName = "lenko"; };
          }
        ];
      };
    };
  };
}
