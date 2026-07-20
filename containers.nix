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

  systemd.services.cockpit-container = {
    description = "Cockpit Web Service Container";
    after = [ "network-online.target" "podman.service" ];
    requires = [ "network-online.target" "podman.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      ExecStartPre = "${pkgs.podman}/bin/podman pull quay.io/cockpit/ws";
      ExecStart = "${pkgs.podman}/bin/podman run --rm --name cockpit-ws --privileged --pid=host -v /:/host:rslave -p 9090:9090 quay.io/cockpit/ws /container/atomic-run --local-ssh";
      ExecStop = "${pkgs.podman}/bin/podman stop cockpit-ws";
      Restart = "always";
      RestartSec = 10;
    };
  };

  # Define your containers
  #virtualisation.oci-containers.containers = { };
}