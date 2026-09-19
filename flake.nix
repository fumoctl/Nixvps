{
  description = "FumoNix VPS - Minimal, secure, and declarative server configuration";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-26.05";
    disko.url = "github:nix-community/disko";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, disko, sops-nix, ... }: {
    nixosConfigurations.vps = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        disko.nixosModules.disko
        sops-nix.nixosModules.sops
        ./disk-config.nix
        ./containers.nix
        ./configuration.nix
      ];
    };
  };
}