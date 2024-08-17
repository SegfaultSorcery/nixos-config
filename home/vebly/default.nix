{config, pkgs, pkgs-unstable, lib, fn, inputs, ... }:
{
    users.users.vebly = {
            isNormalUser = true;
            description = "vebly";
            extraGroups = [ "networkmanager" "wheel" "syncthing"];
            initialPassword = "123";
    };
    services.syncthing = {
        enable = true;
        user = "vebly";
        dataDir = "/home/vebly/Sync";
        configDir = "/home/vebly/.config/syncthing";
        systemService = true;
        openDefaultPorts = true; #TCP/UDP 22000 for transfer
        package = pkgs-unstable.syncthing.overrideAttrs {
            version = "1.27.9";
        };
        settings = {
            devices = {
                "desktop" = {
                    name = "desktop";
                    id = "OFWTVXT-BMDHJVS-YLUXQPJ-34BFIXX-RW2FQZ4-4LCI3TF-FHJIZ5C-4IT5CAV";
                    autoAcceptFolders = true;
                };
                "thinkpad" = {
                    name = "thinkpad";
                    id = "R57OWQ4-ZCSYSQ7-EBIBLUU-U2ZBR4S-KE25GAB-S73M6KE-7EFIWBC-XTQY5AU";
                };
                "tablet" = {
                    name = "tablet";
                    id = "KKUXA3Y-Q3JFJLA-J5UFQ7W-HY6TSYG-YEKUL27-BM3JLCI-IOXBIUY-I4FLNA7";
                    addresses = [
                        "tcp://192.168.1.196:22000"
                    ];
                };
            };
            folders = {
                "SecondBrain" = { #Obsidian Vault
                    enable = true;
                    label = "SecondBrain";
                    path = "/home/vebly/Sync/SecondBrain"; # Tilde is shortcut for /var/lib/syncthing
                    copyOwndershipFromParent = true;
                    devices = [
                        "desktop"
                        "thinkpad"
                        "tablet"
                    ];
                }; 
            };
            options = {
                relaysEnabled = false;
            };
        };
    };

    home-manager = {
        users.vebly = {
	    imports = [
            ../../modules/user/sh/zsh/zsh.nix
            ../../modules/user/wm/awesome.nix 
            ../../modules/user/dev
            ../../modules/user/apps/kitty.nix
            ../../modules/user/apps/tmux.nix
            ../../modules/user/apps/latex.nix
            ../../modules/user/apps/librewolf.nix
        ];
            home.username = "vebly";
            home.homeDirectory = "/home/vebly";

            home.stateVersion = "24.05"; 
            home.packages = with pkgs; [
                    discord
                    arandr
                    obsidian
                    dbeaver-bin
                    octaveFull
                    ani-cli
                    manga-cli
                    mpv

                # Office
                    okular
                    zathura

            ] ++ (with pkgs-unstable;[
                    freetube
                    youtube-dl
                    ytmdl
            ]);

            programs.git = {
                enable = true;
                userName = "vebly";
                userEmail = "";
            };

            home.sessionVariables = {
                EDITOR = "invim";
            };
# Let Home Manager install and manage itself.
            programs.home-manager.enable = true;
        };
    };
}
