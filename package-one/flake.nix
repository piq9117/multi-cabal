{
  description = "A very basic flake";

  inputs.nixpkgs.url = "nixpkgs/nixos-22.05";

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);
      nixpkgsFor = forAllSystems (system: import nixpkgs {
        inherit system;
        overlays = [self.overlay];
      });

    in {
      overlay = final: prev: {
        package-one = final.haskellPackages.callCabal2nix "package-one" ./. {};
      };

      packages = forAllSystems (system: {
        default = nixpkgsFor.${system}.package-one;
      });

      devShells = forAllSystems(system:
        let pkgs = nixpkgsFor.${system};
        in {
          default = pkgs.mkShell {
            packages = [];
            buildInputs = with pkgs; [
              cabal-install
              haskell.compiler.ghc924
              ghcid
            ];
          shellHook = "export PS1='[$PWD]\n❄ '";
          };
        });
    };
}
