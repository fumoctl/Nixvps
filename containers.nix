{ pkgs, ... }: {

  virtualisation = {
    docker.enable = false; # Disable Docker if using Podman
    podman = {
      enable = true;
      dockerCompat = true; # Aliases docker -> podman
      defaultNetwork.settings.dns_enabled = true;
      extraPackages = [ pkgs.podman-compose ];
    };
  };

  # Enable Podman backend
  virtualisation.oci-containers.backend = "podman";

  # Define your containers
  #virtualisation.oci-containers.containers = { };
}