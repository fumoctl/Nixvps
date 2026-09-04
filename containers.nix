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
    podman-compose
    helm
    kubectl
  ];

  # Enable Podman backend
  virtualisation.oci-containers.backend = "podman";

  # Format: <backend>-<container_name>.service

  # Define your containers
  virtualisation.oci-containers.containers = {
    my-service = {
      image = "docker.io/nginx:alpine";
      autoStart = true;
      podman.user = "fumovps";
    };
  };
}
