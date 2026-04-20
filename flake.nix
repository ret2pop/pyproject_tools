{
  description = "Poetry Python dev shell with CUDA + common native libs";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      forAllSystems = f:
        nixpkgs.lib.genAttrs systems (system: f system);
    in
      {
        devShells = forAllSystems (system:
          let
            pkgs = import nixpkgs {
              inherit system;
              config = {
                allowUnfree = true;
                cudaSupport = true;
              };
            };

            python = pkgs.python312;

            nativeBuildInputs = with pkgs; [
              pkg-config
              gcc
              gfortran
              gnumake
              cmake
              ninja
              patchelf
              git
              poetry
            ];

            # Shared libraries go here
            buildInputs = with pkgs; [
              stdenv.cc.cc.lib
              zlib
              openssl
              libffi
              sqlite
              xz
              bzip2
              readline
              ncurses
              expat
              openblas
              glib
              libGL
              libxkbcommon
              libxcb
              libudev-zero
              alsa-lib
              ffmpeg
              cudaPackages.cudatoolkit
              cudaPackages.cudnn
              wayland
              mesa
              xorg.libX11
              xorg.libXcursor
              xorg.libXi
              xorg.libXrandr
            ];

          in
            {
              default = pkgs.mkShell {
                name = "poetry-general-shell";

                packages = [ python ];
                
                inherit nativeBuildInputs buildInputs;
                LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath buildInputs;

                CUDA_PATH = "${pkgs.cudaPackages.cudatoolkit}";
                CUDA_HOME = "${pkgs.cudaPackages.cudatoolkit}";
                POETRY_VIRTUALENVS_CREATE = "true";
                POETRY_VIRTUALENVS_IN_PROJECT = "true";
                
                WAYLAND_DISPLAY = "";
                XDG_SESSION_TYPE = "x11";

                shellHook = ''
                  direnv allow 2>/dev/null || true

                  if [ -f pyproject.toml ]; then
                    poetry env use ${python}/bin/python >/dev/null 2>&1 || true
                    echo
                    echo "Python: $(which python)"
                    echo "Poetry env: $(poetry env info --path 2>/dev/null || true)"
                    echo "Run once: poetry install"
                    echo "Then:     poetry run python3 main.py"
                    echo
                  fi
                '';
              };
            });
      };
}
