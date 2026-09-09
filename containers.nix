{ config
, lib
, pkgs
, ...
}:

{
  # ============================================================================
  # 1. CONTAINER VIRTUALIZATION ENGINE (PODMAN)
  # ============================================================================
  virtualisation = {
    # Explicitly disable standard Docker daemon to avoid socket and iptables conflicts
    docker.enable = false;

    podman = {
      enable = true;

      # Creates symlinks and wrapper scripts aliasing 'docker' -> 'podman'
      dockerCompat = true;

      # Enable Docker-compatible UNIX socket (/run/podman/podman.sock)
      # Essential for docker-compose, orchestration tools, and container management
      dockerSocket.enable = true;

      # Enable Netavark / Aardvark-dns internal DNS resolution between containers
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  # ============================================================================
  # 2. CONTAINER & KUBERNETES MANAGEMENT PACKAGES
  # ============================================================================
  environment.systemPackages = with pkgs; [
    # --- Container Orchestration & Tooling ---
    podman-compose      # Compose specification implementation for Podman
    podman-tui          # Interactive terminal UI for monitoring pods and containers

    # --- Cloud Native & Kubernetes CLI ---
    kubectl             # Kubernetes command-line cluster management tool
    helm                # Kubernetes package manager and chart deployment utility
  ];

  # ============================================================================
  # 3. DECLARATIVE OCI CONTAINERS
  # ============================================================================
  # Systemd-managed declarative containers using the Podman runtime engine.
  # Automatically generates systemd service units: podman-<container_name>.service
  virtualisation.oci-containers = {
    backend = "podman";

    containers = {
      # Sample declarative service running rootless under user 'fumovps'
      my-service = {
        image = "docker.io/nginx:alpine";
        autoStart = true;
        podman.user = "fumovps";
      };
    };
  };
}
