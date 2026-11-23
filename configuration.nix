{ config
, lib
, pkgs
, modulesPath
, ...
}:

let
  sshKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOHca54EkXUDDTTyQAPUMrPcj/ZktrEc6JTFBn6wHoOf"
  ];
in
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

  fonts.enableDefaultPackages = true;
  programs.xwayland.enable = true;

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
    "net.ipv4.conf.all.rp_filter" = 2;
    "net.ipv4.conf.default.rp_filter" = 2;
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
    "net.ipv4.icmp_ignore_bogus_error_responses" = 1;

    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
    "fs.inotify.max_user_watches" = 524288;
    "fs.inotify.max_user_instances" = 8192;
  };

  systemd.services."user@".serviceConfig.Delegate = "cpu cpuset io memory pids";

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "prohibit-password";
      StreamLocalBindUnlink = "yes";
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
      "docker"
    ];
    openssh.authorizedKeys.keys = sshKeys;
    packages = with pkgs; [ ];
  };

  users.groups.fumovps = { };

  users.users.root.openssh.authorizedKeys.keys = sshKeys;

  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    ohMyZsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [
        "git"
        "sudo"
        "docker"
        "kubectl"
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

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
  };

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
    xwayland-satellite
    mullvad-browser
  ];

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [ ];
  };
  
  documentation.man.cache.enable = true;

  system.stateVersion = "26.05";
}
