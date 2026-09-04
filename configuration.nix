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

  hardware.graphics = {
    enable = true;
  };

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
    nano
    micro-full
    neovim


    # Other highly recommended server utilities
    git
    curl
    tmux
    htop
    ncdu # Great for checking VPS disk usage
  ];

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [

  ];

  documentation.man.cache.enable = true;

  programs.firefox = {
    enable = true;

    # System-wide enterprise policies
    policies = {
      # 1. Telemetry, Studies & Data Collection (Total Lockdown)
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DisableTelemetryServer = true;
      DisablePocket = true;
      DisableFirefoxAccounts = false; # Set to true if you do not use Firefox Sync

      # 2. Set Default Search Engine to Brave Search
      SearchEngines = {
        Default = "Brave Search";
        PreventInstalls = false;
        Add = [
          {
            Name = "Brave Search";
            URLTemplate = "https://search.brave.com/search?q={searchTerms}";
            Alias = "@brave";
            Description = "Privacy-respecting search engine by Brave";
          }
        ];
        Remove = [
          "Google"
          "Bing"
          "Amazon.com"
          "eBay"
        ]; # Clean out tracking-heavy defaults
      };

      # 3. Streamlined Extensions Setup (uBlock Origin + LocalCDN)
      ExtensionSettings = {
        # uBlock Origin
        "uBlock0@raymondhill.net" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
        };
        # Firefox Multi-Account Containers
        "@testpilot-containers" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/multi-account-containers/latest.xpi";
        };
        # Cookie AutoDelete
        "CookieAutoDelete@kennydo.com" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/cookie-autodelete/latest.xpi";
        };
      };

      # 4. Built-in Tracking Protection & UI Cleanup
      EnableTrackingProtection = {
        Value = true;
        Cryptomining = true;
        Fingerprinting = true;
        EmailTracking = true;
      };

      FirefoxHome = {
        Pocket = false;
        Snippets = false;
        SponsoredTopSites = false;
        SponsoredStories = false;
        Highlights = false;
      };

      UserMessaging = {
        ExtensionRecommendations = false;
        SkipOnboarding = true;
        WhatsNew = false;
        FeatureRecommendations = false;
      };

      # Forces the browser language context to English to make your fingerprint less unique
      RequestedLocales = [ "en-US" ];

      # 5. Core Privacy Preferences overrides (about:config level via policy)
      Preferences = {
        "privacy.privacyandsecurity.fingerprinting.protection" = true;
        "privacy.query_stripping.enabled" = true; # Strips tracking tokens (like fbclid, utm_) from URLs
        "media.peerconnection.enabled" = false; # Prevents WebRTC from leaking your real IP behind a VPN
        "network.dns.disablePrefetch" = true; # Stops DNS lookups to links before you click them
        "network.prefetch-next" = false;
        "browser.ml.chat.enabled" = false; # Turns off default local AI integrations/network calls
        "browser.ml.linkPreview.enabled" = false;
        "dom.security.https_only_mode" = true;
        "privacy.trackingprotection.enabled" = true;
      };
    };
  };

  system.stateVersion = "26.05";
}
