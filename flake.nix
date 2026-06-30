{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, disko, ... }: {
    nixosConfigurations.vps = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        disko.nixosModules.disko
        ./disk-config.nix
        ./containers.nix
        ({ modulesPath, lib, pkgs, ... }: {
          imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
          
          # 1. Identity & Network
          networking.hostName = "fumonix-vps";
          networking.useDHCP = lib.mkDefault true;
          time.timeZone = "UTC"; # Servers generally run on UTC to keep logs standardized

          # 2. Bootloader
          boot.loader.grub.enable = true;

          # 3. Security & Firewall
          networking.firewall.enable = true;
          networking.firewall.allowedTCPPorts = [ 22 80 443 ];
          
          services.fail2ban.enable = true;

          # 4. SSH Hardening
          services.openssh = {
            enable = true;
            settings = {
              PasswordAuthentication = false;
              KbdInteractiveAuthentication = false;
              PermitRootLogin = "prohibit-password";
            };
          };

          # 5. User Management
          users.users.fumovps = {
            isNormalUser = true;
            linger = true;
            extraGroups = [ "wheel" ]; # Enables sudo
            openssh.authorizedKeys.keys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOHca54EkXUDDTTyQAPUMrPcj/ZktrEc6JTFBn6wHoOf"
            ];
            # Packages only visible when logged into this account
            packages = with pkgs; [
              
            ];
          };
          users.users.root.openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOHca54EkXUDDTTyQAPUMrPcj/ZktrEc6JTFBn6wHoOf"
          ];

          # 6. Maintenance & Performance
          services.cockpit = {
            enable = true;
            port = 9090;
            openFirewall = false; # Automatically handles opening port 9090 in networking.firewall
            
            # Optional: Install the Podman integration plugin
            plugins = with pkgs; [
              cockpit-podman
            ];
            
            settings = {
              WebService = {
                AllowUnencrypted = true; # Useful if you plan to reverse-proxy it through Caddy
              };
            };
          };
          services.qemuGuest.enable = true;
          nix.settings.experimental-features = [ "nix-command" "flakes" ];
          nix.settings.auto-optimise-store = true;
          nix.gc = {
            automatic = true;
            dates = "weekly";
            options = "--delete-older-than 14d";
          };
          swapDevices = [ { device = "/var/lib/swapfile"; size = 2048; } ];

          environment.systemPackages = with pkgs; [
            fastfetch

            # Core tools
            waypipe
            rclone

            # Other highly recommended server utilities
            git
            curl
            tmux
            htop
            ncdu # Great for checking VPS disk usage
          ];

          system.stateVersion = "26.05"; 
        })
      ];
    };
  };
}