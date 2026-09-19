{ config
, lib
, pkgs
, ...
}:

{
  virtualisation = {
    docker.enable = false;

    podman = {
      enable = true;
      dockerCompat = true;
      dockerSocket.enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  environment.systemPackages = with pkgs; [
    podman-compose
    podman-tui
    podman-desktop
    kubectl
    helm
  ];

  virtualisation.oci-containers = {
    backend = "podman";

    containers = {
      my-service = {
        image = "docker.io/nginx:alpine";
        autoStart = true;
        podman.user = "fumovps";
      };
    };
  };
}
