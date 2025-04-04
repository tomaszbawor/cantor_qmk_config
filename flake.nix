{
  description = "Build Cantor firmware from JSON config with vendored QMK";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        jsonConfig = ./cantor.json;

        # ✅ Fetch QMK with submodules
        qmk_firmware = pkgs.fetchgit {
          url = "https://github.com/qmk/qmk_firmware.git";
          rev =
            "bc42a7ea8980c1d135ac6f2d2ec194e3e7355bfe"; # pin to your preferred revision
          sha256 =
            "sha256-o9Zqy9MXqU34/SBRwMkSG0byKkW15i+TpT9FV5Iyvuo="; # update with `nix-prefetch`
          fetchSubmodules = true;
        };

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
            chmod -R u+w ./qmk

            export QMK_HOME=$PWD/qmk
            export PATH=$PATH:$QMK_HOME/bin

            echo "Creating fake git repo for QMK..."
            cd $QMK_HOME
            git init -q
            git config user.email "you@example.com"
            git config user.name "Fake Git User"
            git add .
            git commit -q -m "Fake initial commit"
            cd -

            echo "Configuring QMK..."
            qmk config user.qmk_home="$QMK_HOME"

            echo "Importing JSON keymap..."
            cp ${jsonConfig} keymap.json

            echo "Building firmware..."
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
            chmod -R u+w ./qmk

            export QMK_HOME=$PWD/qmk
            export PATH=$PATH:$QMK_HOME/bin

            qmk config user.qmk_home="$QMK_HOME"
            echo "QMK dev shell ready."
          '';
        };
      });
}
