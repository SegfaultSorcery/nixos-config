{config, pkgs, pkgs-unstable, ...}:
let 
    awesomeConfig = pkgs.fetchFromGitHub {
        owner = "SegfaultSorcery";
        repo = "awesome-config";
        rev = "master";  # or a specific commit hash
            sha256 = "sha256-nwotzGcORI3L0LioLiJebwwbLdHEt4FrXI7AsWdVvEM=";  
    };
in
{
    # 
    imports = [
        ./rofi/rofi.nix
    ];  
    xsession.windowManager.awesome = {
        enable = true;
        package = pkgs.awesome;
        luaModules = with pkgs.lua54Packages; [vicious lgi];
    };
    #
    home.file."awesome" = {
        source = "${awesomeConfig}";
        target = ".config/awesome";
        recursive = true;
    };
    home.packages = with pkgs; [
        nitrogen
        picom
        xclip
        acpi
        brightnessctl
    ];

}
