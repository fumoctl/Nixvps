{ config
, lib
, pkgs
, modulesPath
, ...
}:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  networking.hostName = "nixvps";
  networking.useDHCP = lib.mkDefault true;
  networking.enableIPv6 = true;
  time.timeZone = "UTC";

  boot.kernelModules = [ "tun" "wireguard" ];

  boot.loader.grub.enable = true;

  hardware.graphics = {
    enable = true;
  };

  services.qemuGuest.enable = true;

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22
      80
      443
    ];
  };

  services.fail2ban.enable = true;

  boot.kernel.sysctl = {
    "net.ipv4.tcp_syncookies" = 1;
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
    "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  users.users.fumovps = {
    isNormalUser = true;
    shell = pkgs.zsh;
    linger = true;
    autoSubUidGidRange = true;
    extraGroups = [
      "wheel"
      "podman"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOHca54EkXUDDTTyQAPUMrPcj/ZktrEc6JTFBn6wHoOf"
    ];
    packages = with pkgs; [ ];
  };

  users.groups.fumovps = { };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOHca54EkXUDDTTyQAPUMrPcj/ZktrEc6JTFBn6wHoOf"
  ];

  programs.zsh = {
    enable = true;
    ohMyZsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [
        "git"
        "sudo"
        "docker"
        "kubectl"
      ];
      customPkgs = with pkgs; [
        zsh-autosuggestions
        zsh-syntax-highlighting
      ];
    };
  };

  

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [
      "root"
      "@wheel"
    ];
    auto-optimise-store = true;
  };

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
    htop
    ncdu
    ptyxis
    neovim
    micro-full
    nano
    git
    curl
    tmux
    rclone
    python3
    waypipe
    cage
    mullvad-browser
  ];

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [ ];
  };

  documentation.man.cache.enable = true;

  system.stateVersion = "26.05";
}
