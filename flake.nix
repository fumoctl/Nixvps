{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-26.05";
    disko.url = "github:nix-community/disko";
  };

  outputs = { nixpkgs, disko, ... }: {
    nixosConfigurations.vps = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        disko.nixosModules.disko
        ./disk-config.nix
        ./containers.nix
        ./configuration.nix
      ];
    };
  };
}