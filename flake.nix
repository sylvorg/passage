{
  inputs = {
    devenv.url = "github:cachix/devenv";
    flake-compat.url = "https://flakehub.com/f/edolstra/flake-compat/1.tar.gz";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
  };
  outputs = inputs@{ flake-parts, ... }:
    let inherit (inputs.nixpkgs) lib;
    in flake-parts.lib.mkFlake { inherit inputs; } {
      imports =
        [ flake-parts.flakeModules.easyOverlay inputs.devenv.flakeModule ];
      systems = lib.systems.flakeExposed;
      perSystem = { config, pkgs, final, ... }:
        let binPath = with pkgs; [ sops eza expect ];
        in {
          overlayAttrs = { inherit (config.packages) passage; };
          packages = rec {
            default = passage;
            passage = pkgs.passage.overrideAttrs (old: {
              src = ./.;
              extraPath = old.extraPath + ":" + (lib.makeBinPath binPath);
            });
          };
          devenv.shells = rec {
            default = passage;
            passage.packages = with pkgs;
              binPath ++ [ config.packages.default age tree nixfmt-classic ];
          };
        };
    };
}
