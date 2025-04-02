{
  description = "Build Cantor firmware from JSON config with vendored QMK";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    qmk_firmware = {
      url = "github:qmk/qmk_firmware";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, qmk_firmware }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        jsonConfig = ./cantor.json;

        pythonEnv = pkgs.python3.withPackages (ps:
          with ps; [
            milc
            pygments
            intelhex
            pillow
            hidapi
            requests
            pyusb
          ]);
      in {
        packages.default = pkgs.stdenv.mkDerivation {
          name = "cantor-firmware";
          src = ./.;

          nativeBuildInputs = [ pkgs.qmk pkgs.git pythonEnv pkgs.coreutils ];

          buildPhase = ''
            export HOME=$TMPDIR/home
            mkdir -p $HOME

            echo "Copying QMK firmware to writable directory..."
            cp -r ${qmk_firmware} ./qmk
            export QMK_HOME=$PWD/qmk
            export PATH=$PATH:$QMK_HOME/bin

            echo "Configuring QMK..."
            qmk config user.qmk_home="$QMK_HOME"

            echo "Importing JSON keymap..."
            cp ${jsonConfig} keymap.json

            qmk compile keymap.json
          '';

          installPhase = ''
            mkdir -p $out
            cp $QMK_HOME/.build/*.hex $out/ || true
            cp $QMK_HOME/.build/*.bin $out/ || true
          '';
        };

        devShells.default = pkgs.mkShell {
          buildInputs = [ pkgs.qmk pythonEnv ];

          shellHook = ''
            export HOME=$PWD/.nix-qmk-home
            mkdir -p $HOME

            echo "Copying QMK firmware to local dir..."
            cp -r ${qmk_firmware} ./qmk 2>/dev/null || true
            export QMK_HOME=$PWD/qmk
            export PATH=$PATH:$QMK_HOME/bin

            qmk config user.qmk_home="$QMK_HOME"
            echo "QMK dev shell ready."
          '';
        };
      });
}

