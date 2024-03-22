{
  description = "My haskell library";

  nixConfig = {
    extra-substituters = [
      "https://haskell-language-server.cachix.org"
    ];
    extra-trusted-public-keys = [
      "haskell-language-server.cachix.org-1:juFfHrwkOxqIOZShtC4YC1uT1bBcq2RSvC7OMKx0Nz8="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/haskell-updates";
    flake-utils.url = "github:numtide/flake-utils";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };

    # cabal hashes contains all the version for different haskell packages, to update:
    # nix flake lock --update-input all-cabal-hashes-unpacked
    all-cabal-hashes-unpacked = {
      url = "github:commercialhaskell/all-cabal-hashes/current-hackage";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let

        compilerVersion = "98";

        haskellOverlay = hnew: hold: with pkgs.haskell.lib; { };

        pkgs = import nixpkgs {
          inherit system;
          config = { allowUnfree = false; allowBroken = true; };
          overlays = [
            # final: prev: =
          ];
        };

        hsPkgs = pkgs.haskell.packages."ghc${compilerVersion}";

        # modifier used in haskellPackages.developPackage
        myModifier = drv:
          pkgs.haskell.lib.addBuildTools drv (with hsPkgs; [
            cabal-install
            haskell-language-server
            # TODO use the one from nixpkgs instead
          ]);

        # mkDevShell
        mkPackage = name:
          hsPkgs.developPackage {
            root = pkgs.lib.cleanSource (builtins.toPath ./. + "/${name}");
            name = name;
            returnShellEnv = false;
            withHoogle = true;
            overrides = haskellOverlay;
            modifier = myModifier;
          };

      in
      {
        packages = {
          default = mkPackage "selda";
        };

        devShells = {
          default = pkgs.mkShell {
            name = "ghc${compilerVersion}-haskell-env";
            packages =
              let
                ghcEnv = hsPkgs.ghcWithPackages (hs: [
                  hs.ghc
                  hs.haskell-language-server
                  hs.cabal-install
                  # prev.cairo
                ]);
              in
              [
                ghcEnv
                pkgs.postgresql.out
                # ghc
                pkgs.pkg-config
              ];
          };

        };
      });
}
