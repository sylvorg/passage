{
  inputs = {
    devenv.url = "github:cachix/devenv";
    flake-compat.url = "https://flakehub.com/f/edolstra/flake-compat/1.tar.gz";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:nixos/nixpkgs?ref=pull/524417/merge";
    pass-genphrase = {
      url = "github:congma/pass-genphrase?ref=pull/6/merge";
      flake = false;
    };
  };
  outputs =
    inputs@{ flake-parts, ... }:
    let
      inherit (inputs.nixpkgs) lib;
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        flake-parts.flakeModules.easyOverlay
        inputs.devenv.flakeModule
      ];
      systems = lib.systems.flakeExposed;
      perSystem =
        {
          config,
          pkgs,
          final,
          system,
          ...
        }:
        let
          binPath = with pkgs; [
            age
            eza
            fd
            ripgrep
            sops
          ];
        in
        {
          overlayAttrs = {
            inherit (config.packages) passage;
            pass = inputs.nixpkgs.legacyPackages.${system}.pass.overrideAttrs (old: {
              passthru = old.passthru // {
                extensions = old.passthru.extensions // {
                  pass-genphrase = old.passthru.extensions.pass-genphrase.overrideAttrs (gold: {
                    src = inputs.pass-genphrase;
                  });
                };
              };
            });
          };
          packages = rec {
            default = passage;
            passage = pkgs.passage.overrideAttrs (old: {
              src = ./.;
              extraPath = old.extraPath + ":" + (lib.makeBinPath binPath);
              postInstall = ''
                substituteInPlace $out/bin/passage \
                  --replace-fail 'SOPS="''${PASSAGE_SOPS:-sops}"' 'SOPS=${lib.getExe pkgs.sops}'
              '' + old.postInstall;
            });
          };
          devenv.shells = rec {
            default = passage;
            passage.packages =
              with pkgs;
              binPath
              ++ [
                config.packages.default
                fish
                nixfmt-classic
                zsh
              ];
          };
        };
    };
}
