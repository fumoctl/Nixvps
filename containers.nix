{ pkgs, ... }: {

  # Enable Podman backend
  virtualisation.oci-containers.backend = "podman";

  # Define your containers
  #virtualisation.oci-containers.containers = { };
}