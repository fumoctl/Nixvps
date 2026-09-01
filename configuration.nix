{
  modulesPath,
  lib,
  pkgs,
  ...
}:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  # 1. Identity & Network
  networking.hostName = "fumonix-vps";
  networking.useDHCP = lib.mkDefault true;
  networking.enableIPv6 = true;
  time.timeZone = "UTC"; # Servers generally run on UTC to keep logs standardized

  # 2. Bootloader
  boot.loader.grub.enable = true;

  # 3. Security & Firewall
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [
    22
    80
    443
  ];

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
    autoSubUidGidRange = true;
    extraGroups = [
      "wheel"
      "docker"
      "podman"
      "OCI"
    ]; # "wheel" Enables sudo
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOHca54EkXUDDTTyQAPUMrPcj/ZktrEc6JTFBn6wHoOf"
    ];
    # Packages only visible when logged into this account
    packages = with pkgs; [

    ];
  };
  users.groups.fumovps = { };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOHca54EkXUDDTTyQAPUMrPcj/ZktrEc6JTFBn6wHoOf"
  ];

  # 6. Maintenance & Performance
  services.qemuGuest.enable = true;
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 2048;
    }
  ];

  environment.systemPackages = with pkgs; [
    fastfetch

    # Core tools
    waypipe
    cage
    rclone
    python3

    # Other highly recommended server utilities
    git
    curl
    tmux
    htop
    ncdu # Great for checking VPS disk usage
  ];

  system.stateVersion = "26.05";
}
