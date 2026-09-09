{ config
, lib
, pkgs
, modulesPath
, ...
}:

{
  # ============================================================================
  # 1. MODULE IMPORTS
  # ============================================================================
  imports = [
    # Baseline hardware and kernel driver profile for QEMU / KVM virtualized guests
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  # ============================================================================
  # 2. SYSTEM IDENTITY & NETWORKING
  # ============================================================================
  # Host identifier
  networking.hostName = "fumonix-vps";

  # Dynamic host configuration across all detected network interfaces
  networking.useDHCP = lib.mkDefault true;

  # Explicit IPv6 stack enablement for modern cloud dual-stack networking
  networking.enableIPv6 = true;

  # Servers standardize on UTC to ensure coherent timestamping across distributed
  # system logs, journald entries, container telemetry, and audit trails
  time.timeZone = "UTC";

  # ============================================================================
  # 3. BOOTLOADER & HARDWARE ACCELERATION
  # ============================================================================
  # GRUB bootloader configured for legacy BIOS / cloud hypervisors with GPT disklabel
  # (Pairs with the Disko 1MB EF02 BIOS boot partition on /dev/sda)
  boot.loader.grub.enable = true;

  # Hardware Direct Rendering Infrastructure (DRI) graphics enablement.
  # Essential for headless Wayland compositors (Cage) and Waypipe to leverage
  # virtualized GPU / software-rasterized Mesa rendering for remote graphical apps
  hardware.graphics = {
    enable = true;
  };

  # ============================================================================
  # 4. HYPERVISOR INTEGRATION
  # ============================================================================
  # QEMU Guest Agent daemon: enables the host hypervisor to coordinate graceful
  # ACPI shutdowns, filesystem freezing during backups, and host-guest time synchronization
  services.qemuGuest.enable = true;

  # ============================================================================
  # 5. SECURITY, FIREWALL & INTRUSION PREVENTION
  # ============================================================================
  networking.firewall = {
    enable = true;

    # Inbound TCP service ports:
    # 22  - OpenSSH secure shell & Waypipe tunneling
    # 80  - HTTP reverse proxy / Let's Encrypt ACME verification
    # 443 - HTTPS encrypted web traffic
    allowedTCPPorts = [
      22
      80
      443
    ];
  };

  # Fail2ban scans system authentication logs (sshd) and dynamically blocks IPs
  # that exhibit repeated authentication failures, mitigating automated brute-force attacks
  services.fail2ban.enable = true;

  # Linux Kernel TCP/IP stack hardening against common network attacks
  boot.kernel.sysctl = {
    # Mitigate SYN flood Denial of Service attacks using cryptographic cookies
    "net.ipv4.tcp_syncookies" = 1;

    # Enable Reverse Path Filtering to protect against IP address spoofing
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;

    # Reject ICMP redirect packets to prevent Man-in-the-Middle route alterations
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;

    # Do not send ICMP redirects (host is a standalone server, not a router)
    "net.ipv4.conf.all.send_redirects" = 0;

    # Ignore ICMP broadcast pings and bogus error responses (Smurf attack defense)
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
    "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
  };

  # ============================================================================
  # 6. SSH SERVER HARDENING
  # ============================================================================
  services.openssh = {
    enable = true;
    settings = {
      # Disallow password authentication; require cryptographic SSH public keys
      PasswordAuthentication = false;

      # Disable PAM keyboard-interactive authentication to prevent password prompting
      KbdInteractiveAuthentication = false;

      # Restrict direct root login to public-key authentication only
      PermitRootLogin = "prohibit-password";
    };
  };

  # ============================================================================
  # 7. USER ACCOUNTS & PRIVILEGES
  # ============================================================================
  users.users.fumovps = {
    isNormalUser = true;

    # Enables systemd user session lingering so rootless Podman containers and user
    # services persist across logouts and start on boot without an active SSH session
    linger = true;

    # Automatically allocates subUID and subGID ranges (/etc/subuid, /etc/subgid)
    # required for rootless user namespaces and UID mapping in Podman
    autoSubUidGidRange = true;

    # Principle of least privilege:
    # - 'wheel': Sudo administrative access
    # - 'podman': Access to manage Podman containers
    # (The 'docker' group is omitted as it grants root-equivalent host access)
    extraGroups = [
      "wheel"
      "podman"
    ];

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOHca54EkXUDDTTyQAPUMrPcj/ZktrEc6JTFBn6wHoOf"
    ];

    # Packages installed strictly into the fumovps user environment
    packages = with pkgs; [ ];
  };

  users.groups.fumovps = { };

  # Authorized SSH deployment keys for the root account
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOHca54EkXUDDTTyQAPUMrPcj/ZktrEc6JTFBn6wHoOf"
  ];

  # ============================================================================
  # 8. NIX PACKAGE MANAGER & STORAGE HYGIENE
  # ============================================================================
  nix.settings = {
    # Activate modern Nix CLI and Flakes support
    experimental-features = [
      "nix-command"
      "flakes"
    ];

    # Restrict privileged Nix daemon operations (substituters, binary caches)
    # strictly to root and members of the wheel administrative group
    trusted-users = [
      "root"
      "@wheel"
    ];

    # Automatically hardlinks identical files across the /nix/store on build,
    # significantly reducing disk footprint on cloud VPS storage volumes
    auto-optimise-store = true;
  };

  # Automated Nix store garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # 2GB swapfile provides an emergency memory buffer to protect the Linux kernel
  # OOM (Out-Of-Memory) killer from terminating critical services during heavy builds
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 2048; # Size in Megabytes (2 GB)
    }
  ];

  # ============================================================================
  # 9. SYSTEM PACKAGES & SERVER UTILITIES
  # ============================================================================
  environment.systemPackages = with pkgs; [
    # --- System Information & Monitoring ---
    fastfetch       # Modern, performant system information fetching tool
    htop            # Interactive process viewer and resource monitor
    ncdu            # NCurses disk usage analyzer for rapid VPS storage audits

    # --- Terminal Text Editors ---
    neovim          # Extensible, modern modal text editor
    micro-full      # Intuitive terminal text editor with full syntax highlighting & plugins
    nano            # Lightweight, ubiquitous fallback editor

    # --- Core CLI Utilities & Data Transfer ---
    git             # Distributed version control system
    curl            # Command-line data transfer utility supporting HTTP/HTTPS
    tmux            # Terminal multiplexer for persistent remote sessions
    rclone          # Cloud storage sync and file transfer CLI tool
    python3         # Python scripting runtime for administration and automation

    # --- Remote Wayland & GUI Forwarding ---
    waypipe         # Transparent Wayland compositor forwarding proxy over SSH
    cage            # Kiosk Wayland compositor for running isolated graphical apps headlessly
  ];

  # ============================================================================
  # 10. BINARY COMPATIBILITY & SYSTEM DOCUMENTATION
  # ============================================================================
  # nix-ld executes unpatched dynamically linked FHS binaries on NixOS by providing
  # a standard glibc interpreter shim (/lib64/ld-linux-x86-64.so.2)
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [ ];
  };

  # Pre-indexes manpages into a binary cache database for fast 'man -k' / 'apropos' search
  documentation.man.cache.enable = true;

  # ============================================================================
  # 11. REMOTE HARDENED BROWSER (FIREFOX ENTERPRISE)
  # ============================================================================
  # System-wide Firefox installation pre-configured via enterprise JSON policies.
  # Intended for secure, private remote browsing streamed over Waypipe + Cage.
  programs.firefox = {
    enable = true;

    policies = {
      # ------------------------------------------------------------------------
      # Telemetry, Studies & Data Collection Lockdown
      # ------------------------------------------------------------------------
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DisableTelemetryServer = true;
      DisablePocket = true;
      DisableFirefoxAccounts = false; # Set to true if not utilizing Firefox Sync

      # ------------------------------------------------------------------------
      # Search Engine Configuration (Privacy-First Default)
      # ------------------------------------------------------------------------
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
        ]; # Strip tracking-heavy and ad-laden default search engines
      };

      # ------------------------------------------------------------------------
      # Mandatory Extensions Setup
      # ------------------------------------------------------------------------
      ExtensionSettings = {
        # uBlock Origin (Wide-spectrum ad and tracker blocking)
        "uBlock0@raymondhill.net" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
        };

        # Firefox Multi-Account Containers (Contextual identity & cookie isolation)
        "@testpilot-containers" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/multi-account-containers/latest.xpi";
        };

        # Cookie AutoDelete (Automatic state cleanup when tabs close)
        "CookieAutoDelete@kennydo.com" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/cookie-autodelete/latest.xpi";
        };
      };

      # ------------------------------------------------------------------------
      # Tracking Protection & UI Cleanliness
      # ------------------------------------------------------------------------
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

      # Enforce uniform en-US locale to minimize browser fingerprinting entropy
      RequestedLocales = [ "en-US" ];

      # ------------------------------------------------------------------------
      # Low-Level Security & Privacy Overrides (about:config)
      # ------------------------------------------------------------------------
      Preferences = {
        # Fingerprinting protection & anti-canvas probing
        "privacy.privacyandsecurity.fingerprinting.protection" = true;

        # Strips tracking query tokens (e.g. fbclid, utm_, gclid) from visited URLs
        "privacy.query_stripping.enabled" = true;

        # Disable WebRTC peer connection to eliminate local/public IP address leaks
        "media.peerconnection.enabled" = false;

        # Disable DNS and speculative link prefetching to preserve DNS query privacy
        "network.dns.disablePrefetch" = true;
        "network.prefetch-next" = false;

        # Disable telemetry-backed ML/AI local integrations
        "browser.ml.chat.enabled" = false;
        "browser.ml.linkPreview.enabled" = false;

        # Enforce HTTPS-Only Mode across all browser navigation
        "dom.security.https_only_mode" = true;
        "privacy.trackingprotection.enabled" = true;
      };
    };
  };

  # ============================================================================
  # 12. SYSTEM RELEASE & STATE VERSION
  # ============================================================================
  # This value determines the NixOS release from which default settings and state
  # file locations were initially configured.
  # DO NOT modify this value after initial system deployment.
  system.stateVersion = "26.05";
}
