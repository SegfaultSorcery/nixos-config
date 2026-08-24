{ config, pkgs, ... }:

let
  immichMlCompose = pkgs.writeText "immich-ml-compose.yml" ''
    name: immich_remote_ml
    services:
      immich-machine-learning:
        container_name: immich_machine_learning
        image: ghcr.io/immich-app/immich-machine-learning:release-cuda
        volumes:
          - model-cache:/cache
        ports:
          - '3003:3003'
        restart: always
        devices:
          - nvidia.com/gpu=all
    volumes:
      model-cache:
  '';
in
{
  networking.firewall.allowedTCPPorts = [ 3003 ];
  virtualisation.docker.enable = true;
  virtualisation.docker.daemon.settings.features.cdi = true;

  systemd.services.immich-ml = {
    description = "Immich Machine Learning";
    after = [ "docker.service" "network-online.target" ];
    requires = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.docker}/bin/docker compose -f ${immichMlCompose} -p immich_remote_ml up -d";
      ExecStop = "${pkgs.docker}/bin/docker compose -f ${immichMlCompose} -p immich_remote_ml down";
    };
  };
}
