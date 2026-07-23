{ pkgs, ... }: {

  virtualisation = {
    docker.enable = false; # Disable Docker if using Podman
    podman = {
      enable = true;
      dockerCompat = true; # Aliases docker -> podman
      dockerSocket.enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };
  environment.systemPackages = with pkgs; [
      podman-tui
      podman-desktop
      podman-compose
      helm
      kubectl
      kind
  ];

  # Enable Podman backend
  virtualisation.oci-containers.backend = "podman";

  # Format: <backend>-<container_name>.service

  # Define your containers
  virtualisation.oci-containers.containers = {
    podmanhello = {
      image = "quay.io/podman/hello:latest";
      autoStart = true;
    };
  };
}