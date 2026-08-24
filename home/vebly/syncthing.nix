{
  config,
  pkgs,
  pkgs-unstable,
  lib,
  fn,
  var,
  ...
}: let
  cfg = config.opt.vebly.syncthing;
in {
  options.opt.vebly.syncthing.enable = lib.mkEnableOption "Enable Syncthing";

  config = lib.mkIf cfg.enable {

      sops.secrets = let 
        devices = ["desktop" "thinkpad" "server" "tablet" "ereader"];
        folders = [ "SecondBrain" "Org" "FreeTube" "Studies" "Music" "Books"];
        param = {owner = "vebly"; sopsFile = ../../secrets/vebly/syncthing.yaml;};
        decl_folder_secrets = builtins.listToAttrs (
                builtins.concatLists (builtins.map (folder: [
                { name = "syncthing/folders/${folder}/devices"; value = param; }
                { name = "syncthing/folders/${folder}/path"; value = param; }
            ]) folders)
            );
        decl_device_secrets = builtins.listToAttrs (
                builtins.concatLists (builtins.map (device: [
                {name = "syncthing/devices/${device}/id"; value = param;}
                {name = "syncthing/devices/${device}/addresses"; value = param;}
            ]) devices)
            );
      in decl_device_secrets // decl_folder_secrets;



    system.activationScripts.syncthing.text = ''
    echo "Running syncthing activation"
    ${pkgs.babashka}/bin/bb ${./syncthing_activation.clj}
    echo "end"
    '';

    services.syncthing = {
      enable = true;
      user = "vebly";
      dataDir = "/home/vebly";
      configDir = "/home/vebly/.config/syncthing";
      systemService = true;
      openDefaultPorts = true; #TCP/UDP 22000 for transfer
      overrideDevices = false;
      overrideFolders = true;
      package = pkgs.syncthing;
    };
  };
}
