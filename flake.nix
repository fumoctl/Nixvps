{
  description = "FumoNix VPS - Minimal, secure, and declarative server configuration";

  # ============================================================================
  # 1. FLAKE INPUTS
  # ============================================================================
  inputs = {
    # NixOS official stable release channel
    nixpkgs.url = "nixpkgs/nixos-26.05";

    # Declarative disk partitioning and filesystem formatting
    disko.url = "github:nix-community/disko";
  };

  # ============================================================================
  # 2. FLAKE OUTPUTS & SYSTEM MODULE COMPOSITION
  # ============================================================================
  outputs = { self, nixpkgs, disko, ... }: {
    nixosConfigurations.vps = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        # Disko module for declarative drive partitioning
        disko.nixosModules.disko

        # Storage & partition specifications
        ./disk-config.nix

        # Rootless Podman engine & OCI container services
        ./containers.nix

        # Core OS services, networking, users, security hardening, and tooling
        ./configuration.nix
      ];
    };
  };
}