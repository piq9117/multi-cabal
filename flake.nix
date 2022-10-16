{
  description = "A very basic flake";

  inputs.nixpkgs.url = "nixpkgs/nixos-22.05";

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);
      nixpkgsFor = forAllSystems (system: import nixpkgs {
        inherit system;
        overlays = [
          self.overlay
        ];
      });

    in {
      overlay = (final: prev: {
        main-package = final.haskellPackages.callCabal2nix "main-package" ./main-package {};
        package-one = final.haskellPackages.callCabal2nix "package-one" ./package-one {};
        package-two = final.haskellPackages.callCabal2nix "package-two" ./package-two {};
      });

      packages = forAllSystems (system: {
        main-package = nixpkgsFor.${system}.main-package;
        package-one = nixpkgsFor.${system}.package-one;
        package-two = nixpkgsFor.${system}.package-two;
      });
      devShells = forAllSystems(system:
        let pkgs = nixpkgsFor.${system};
        in {
          default = pkgs.mkShell {
            packages = [
              self.packages.${system}.main-package
              self.packages.${system}.package-one
              self.packages.${system}.package-two
            ];
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
