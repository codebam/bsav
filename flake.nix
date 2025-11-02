{
  description = "A Nix flake for the bsav Node.js script";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        # The package is defined here
        packages.bsav = pkgs.stdenv.mkDerivation {
          pname = "bsav";
          version = "0.1.0";

          # This makes the current directory (including ./scripts) available
          src = ./.;

          # We need the 'makeWrapper' tool to build our package
          nativeBuildInputs = [ pkgs.makeWrapper ];

          # The script that builds and installs the package
          installPhase = ''
            runHook preInstall

            # Create the destination for the real script
            install -Dm755 $src/scripts/bsav $out/libexec/bsav

            # Create a wrapper script in the standard 'bin' directory.
            # This wrapper sets up the PATH before running the real script.
            makeWrapper $out/libexec/bsav $out/bin/bsav \
              --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.nodejs ]}

            runHook postInstall
          '';
        };

        # A convenient alias for 'nix build'
        packages.default = self.packages.${system}.bsav;

        # Make the package runnable with 'nix run'
        apps.bsav = {
          type = "app";
          program = "${self.packages.${system}.bsav}/bin/bsav";
        };

        apps.default = self.apps.${system}.bsav;

        # A development shell with nodejs available for working on the script
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.nodejs
          ];
        };
      });
}
