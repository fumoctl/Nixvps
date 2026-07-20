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
  virtualisation.oci-containers.containers = {
    cockpit = {
      image = "quay.io/cockpit/ws";
      ports = [ "9090:9090" ];
      extraOptions = [
        "--privileged"
        "--pid=host"
      ];
      volumes = [
        "/:/host:rslave"
      ];
      cmd = [ "/container/atomic-run" "--local-ssh" ];
      autoStart = true;
    };
  };
}