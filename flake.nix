{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    systems.url = "github:nix-systems/default";
  };

  outputs = { self, nixpkgs, systems }:
    let
      eachSystem = nixpkgs.lib.genAttrs (import systems);
    in {
      devShells = eachSystem (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in {
          default = pkgs.mkShell {
            packages = with pkgs; [ racket python3 ];
            shellHook = ''
              export PLTADDONDIR="$PWD/.racket"
              raco pkg install --auto --skip-installed --no-docs \
                html-writing css-expr html-parsing markdown
              echo "build: racket build.rkt"
              echo "serve: python3 -m http.server -d dist 8080"
            '';
          };
        });
    };
}
