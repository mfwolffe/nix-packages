{
  description = "mfwolffe's personal packages - Fortran, Rust, Go, C, and Python tools";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        lib = pkgs.lib;

        # Helper for Rust packages
        mkRustPackage = { pname, version, src, cargoHash ? null, cargoLock ? null
          , buildInputs ? [ ], nativeBuildInputs ? [ ], ... }@args:
          pkgs.rustPlatform.buildRustPackage ({
            inherit pname version src;
            cargoHash = cargoHash;
            buildInputs = buildInputs ++ [ pkgs.openssl ];
            nativeBuildInputs = nativeBuildInputs ++ [ pkgs.pkg-config ];
          } // (builtins.removeAttrs args [
            "pname"
            "version"
            "src"
            "cargoHash"
            "buildInputs"
            "nativeBuildInputs"
          ]));

        # Helper for Go packages
        mkGoPackage = { pname, version, src, vendorHash ? null, ... }@args:
          pkgs.buildGoModule ({
            inherit pname version src vendorHash;
          } // (builtins.removeAttrs args [
            "pname"
            "version"
            "src"
            "vendorHash"
          ]));

        # Helper for Fortran packages with make
        mkFortranMakePackage =
          { pname, version, src, buildInputs ? [ ], makeFlags ? [ ], installPhase
          , ... }@args:
          pkgs.stdenv.mkDerivation ({
            inherit pname version src;
            nativeBuildInputs = [ pkgs.gfortran ];
            buildInputs = buildInputs;
            makeFlags = makeFlags;
            inherit installPhase;
          } // (builtins.removeAttrs args [
            "pname"
            "version"
            "src"
            "buildInputs"
            "makeFlags"
            "installPhase"
          ]));

        # Helper for Fortran packages with fpm
        mkFortranFpmPackage =
          { pname, version, src, buildInputs ? [ ], installPhase, ... }@args:
          pkgs.stdenv.mkDerivation ({
            inherit pname version src;
            nativeBuildInputs = [ pkgs.gfortran pkgs.fortran-fpm ];
            buildInputs = buildInputs;
            buildPhase = ''
              fpm build --profile release
            '';
            inherit installPhase;
          } // (builtins.removeAttrs args [
            "pname"
            "version"
            "src"
            "buildInputs"
            "installPhase"
          ]));

        # Helper for C packages with make
        mkCMakePackage =
          { pname, version, src, buildInputs ? [ ], makeFlags ? [ ], installPhase
          , ... }@args:
          pkgs.stdenv.mkDerivation ({
            inherit pname version src;
            nativeBuildInputs = [ pkgs.gnumake ];
            buildInputs = buildInputs;
            makeFlags = makeFlags;
            inherit installPhase;
          } // (builtins.removeAttrs args [
            "pname"
            "version"
            "src"
            "buildInputs"
            "makeFlags"
            "installPhase"
          ]));

        # Helper for Python packages
        mkPythonPackage =
          { pname, version, src, propagatedBuildInputs ? [ ], ... }@args:
          pkgs.python3Packages.buildPythonApplication ({
            inherit pname version src;
            format = "pyproject";
            nativeBuildInputs = with pkgs.python3Packages; [
              setuptools
              wheel
              hatchling
            ];
            propagatedBuildInputs = propagatedBuildInputs;
          } // (builtins.removeAttrs args [
            "pname"
            "version"
            "src"
            "propagatedBuildInputs"
          ]));

      in {
        packages = {
          # ============ RUST PACKAGES ============

          fackr = mkRustPackage {
            pname = "fackr";
            version = "1.1.1";
            src = pkgs.fetchFromGitHub {
              owner = "TenseleyFlow";
              repo = "fackr";
              rev = "v1.1.1";
              hash = "sha256-jDHbhw5/syKPHn+RBefXUbqTloerR3usNYkB/axY2LM=";
            };
            cargoHash = "sha256-LSkTHIvGNynYSsOkXhCh4NIJM73UHt10QgHgTXBjkhU=";
            meta = {
              description =
                "Terminal text editor written in Rust - facsimile reimplementation";
              homepage = "https://github.com/TenseleyFlow/fackr";
              license = pkgs.lib.licenses.mit;
            };
          };

          fussr = mkRustPackage {
            pname = "fussr";
            version = "0.2.13";
            src = pkgs.fetchFromGitHub {
              owner = "tenseleyFlow";
              repo = "fussr";
              rev = "v0.2.13";
              hash = "sha256-GGL4fJo0S1trHrmErRnL+4W8HTV8LfTJgYAZOBwZYCs=";
            };
            cargoHash = "sha256-zi6z9L1MzAwPBh6utL9MWnh/hQ999py4kcniuKLX4wI=";
            buildInputs = with pkgs; [ libgit2 libssh2 openssl zlib ];
            meta = {
              description = "A git staging TUI tool - Rust port of fuss";
              homepage = "https://github.com/tenseleyFlow/fussr";
              license = pkgs.lib.licenses.mit;
            };
          };

          wezztershier-rust = mkRustPackage {
            pname = "wezztershier-rust";
            version = "0.3.0";
            src = pkgs.fetchFromGitHub {
              owner = "tenseleyFlow";
              repo = "wezzteRust";
              rev = "v0.3.0";
              hash = "sha256-WuQVjd87ql9/vQk/J1ZB9mk/qqiF9QWGLFAsjdL5SCA=";
            };
            cargoHash = "sha256-gNwJkRf4adl0nDlfMxvy6QLpBalnHL5Y23CA0OLeWcg=";
            meta = {
              description =
                "High-performance Rust GUI tuner for WezTerm configuration";
              homepage = "https://github.com/tenseleyFlow/wezzteRust";
              license = pkgs.lib.licenses.mit;
            };
          };

          eyescore = mkRustPackage {
            pname = "eyescore";
            version = "1.0.2";
            src = pkgs.fetchFromGitHub {
              owner = "tree3stan-chord";
              repo = "score";
              rev = "v1.0.2";
              hash = "sha256-FU1qJJD3I6i0Jkdo7xa1L+soMPRfQeNsm2zTy6/ZA5Q=";
            };
            cargoHash = "sha256-aMEu2csC6tvk6XhRVQVt1SDPvR1pVLWrO95PfoZ4heQ=";
            buildInputs = with pkgs; [ alsa-lib ];
            postInstall = ''
              mv $out/bin/score $out/bin/eyescore
            '';
            meta = {
              description =
                "Professional CLI Music Notation System - colorized TUI score engraver";
              homepage = "https://github.com/tree3stan-chord/score";
              license = pkgs.lib.licenses.mit;
            };
          };

          # ============ GO PACKAGES ============

          parrot-cli = mkGoPackage {
            pname = "parrot-cli";
            version = "1.8.9";
            src = pkgs.fetchFromGitHub {
              owner = "tenseleyFlow";
              repo = "parrot";
              rev = "v1.8.9";
              hash = "sha256-MbeJpfu5xTpr6VgZuiuS78DZ3xiDL9MqWIBJspAVER0=";
            };
            vendorHash = "sha256-kT0CKC19lvYjNzUS+wUFWTA1IJogiQv/Lf9DQeh30FA=";
            meta = {
              description = "Intelligent roasts of failed commands";
              homepage = "https://github.com/tenseleyFlow/parrot";
              license = pkgs.lib.licenses.mit;
            };
          };

          shellp = mkGoPackage {
            pname = "shellp";
            version = "1.0.0";
            src = pkgs.fetchFromGitHub {
              owner = "tenseleyFlow";
              repo = "shellp-go"; # Note: repo is shellp-go
              rev = "v1.0.0";
              hash = "sha256-yERaSlaJHATZbT4ybiiJkZ88zZE6AJDgBXpG3RNo/VU=";
            };
            vendorHash = "sha256-m5mBubfbXXqXKsygF5j7cHEY+bXhAMcXUts5KBKoLzM=";
            meta = {
              description =
                "Development note-taking companion for documenting shell commands";
              homepage = "https://github.com/tenseleyFlow/shellp";
              license = pkgs.lib.licenses.mit;
            };
          };

          # ============ FORTRAN (FPM) PACKAGES ============

          fortress = mkFortranFpmPackage {
            pname = "fortress";
            version = "1.0.1";
            src = pkgs.fetchFromGitHub {
              owner = "FortranGoingOnForty";
              repo = "fortress";
              rev = "v1.0.1";
              hash = "sha256-NXgJfSeo0WKdEDU/bks6Q4EBCZOnhe8T7TK3OiQkgek=";
            };
            buildInputs = with pkgs; [ fzf git ];
            installPhase = ''
              runHook preInstall
              mkdir -p $out/bin $out/share/fortress
              install -Dm755 build/gfortran_*/app/fortress $out/bin/fortress-bin
              install -Dm644 fortress.sh $out/share/fortress/fortress.sh
              install -Dm644 fortress.fish $out/share/fortress/fortress.fish
              runHook postInstall
            '';
            meta = {
              description =
                "Command-line file explorer written in modern Fortran with cd-on-exit";
              homepage = "https://github.com/FortranGoingOnForty/fortress";
              license = pkgs.lib.licenses.mit;
            };
          };

          facsimile = mkFortranFpmPackage {
            pname = "facsimile";
            version = "0.9.4";
            src = pkgs.fetchFromGitHub {
              owner = "FortranGoingOnForty";
              repo = "facsimile";
              rev = "v0.9.4";
              hash = "sha256-HcYyopfe4PQ5Gb75VPTVsCNuG9azYSyDT63uU2TP5dw=";
            };
            installPhase = ''
              runHook preInstall
              mkdir -p $out/bin
              fac_binary=$(find build -name "fac" -type f)
              install -Dm755 "$fac_binary" $out/bin/fac
              ln -s fac $out/bin/facsimile
              runHook postInstall
            '';
            meta = {
              description =
                "Terminal text editor written in Fortran with VSCode-style keybindings";
              homepage = "https://github.com/FortranGoingOnForty/facsimile";
              license = pkgs.lib.licenses.mit;
            };
          };

          # ============ FORTRAN (MAKE) PACKAGES ============

          fortsh = mkFortranMakePackage {
            pname = "fortsh";
            version = "0.9.3";
            src = pkgs.fetchFromGitHub {
              owner = "FortranGoingOnForty";
              repo = "fortsh";
              rev = "v0.9.3";
              hash = "sha256-0qxrAx2ho9Gn/h+jKl1WK2/rtzs7Tc1hDmVYTxpa72E=";
            };
            buildPhase = "make release";
            installPhase = ''
              runHook preInstall
              mkdir -p $out/bin
              install -Dm755 build/bin/fortsh $out/bin/fortsh
              runHook postInstall
            '';
            meta = {
              description =
                "Fortran Shell - A modern shell implementation with AST-based parsing";
              homepage = "https://github.com/FortranGoingOnForty/fortsh";
              license = pkgs.lib.licenses.mit;
            };
          };

          fit = mkFortranMakePackage {
            pname = "fit";
            version = "0.1.0";
            src = pkgs.fetchFromGitHub {
              owner = "FortranGoingOnForty";
              repo = "fit";
              rev = "v0.1.0";
              hash = "sha256-moHWI5xTpnPda3jCeGeND5ViJg2mk8ukowlfCPOWLq4=";
            };
            buildPhase = "make release";
            installPhase = ''
              runHook preInstall
              mkdir -p $out/bin
              install -Dm755 bin/fit $out/bin/fit
              runHook postInstall
            '';
            meta = {
              description =
                "Terminal-based merge conflict resolver with three-pane TUI interface";
              homepage = "https://github.com/FortranGoingOnForty/fit";
              license = pkgs.lib.licenses.mit;
            };
          };

          fuss = mkFortranMakePackage {
            pname = "fuss";
            version = "1.2.7";
            src = pkgs.fetchFromGitHub {
              owner = "FortranGoingOnForty";
              repo = "fuss";
              rev = "v1.2.7";
              hash = "sha256-ZlHUSSrDfoUMeqi2pj8xQkQX7gFH9a5+de7gS3YE1pA=";
            };
            buildInputs = with pkgs; [ git fzf ];
            installPhase = ''
              runHook preInstall
              mkdir -p $out/bin
              install -Dm755 fuss $out/bin/fuss
              runHook postInstall
            '';
            meta = {
              description =
                "A tree utility for dirty git files, written in modern Fortran";
              homepage = "https://github.com/FortranGoingOnForty/fuss";
              license = pkgs.lib.licenses.mit;
            };
          };

          ferp = mkFortranMakePackage {
            pname = "ferp";
            version = "0.9.1";
            src = pkgs.fetchFromGitHub {
              owner = "FortranGoingOnForty";
              repo = "ferp";
              rev = "v0.9.1";
              hash = "sha256-TFJcXsBYGPs0KnzveIbdySnpn+0gOSqB8YG0B5kv0Vk=";
            };
            nativeBuildInputs = [ pkgs.gfortran pkgs.clang ];
            buildInputs = with pkgs; [ pcre2 ];
            buildPhase = "make release";
            installPhase = ''
              runHook preInstall
              mkdir -p $out/bin
              install -Dm755 ferp $out/bin/ferp
              runHook postInstall
            '';
            meta = {
              description = "A GNU grep clone written in Fortran";
              homepage = "https://github.com/FortranGoingOnForty/ferp";
              license = pkgs.lib.licenses.mit;
            };
          };

          fortbite = mkFortranMakePackage {
            pname = "fortbite";
            version = "1.0.1";
            src = pkgs.fetchFromGitHub {
              owner = "FortranGoingOnForty";
              repo = "fortbite";
              rev = "v1.0.1";
              hash = "sha256-m7YeYbOKqWH+J3xg6TIM5kCG0wd0HvkYcjewottMr9s=";
            };
            buildPhase = ''
              make clean || true
              make all
            '';
            installPhase = ''
              runHook preInstall
              mkdir -p $out/bin
              install -Dm755 build/bin/fortbite $out/bin/fortbite
              runHook postInstall
            '';
            meta = {
              description =
                "High-precision mathematical calculator in Modern Fortran";
              homepage = "https://github.com/FortranGoingOnForty/fortbite";
              license = pkgs.lib.licenses.mit;
            };
          };

          sniffert = mkFortranMakePackage {
            pname = "sniffert";
            version = "0.6.0";
            src = pkgs.fetchFromGitHub {
              owner = "FortranGoingOnForty";
              repo = "sniffert";
              rev = "v0.6.0";
              hash = "sha256-zlafab7f5VB0cpk9EZ1iCn3C/o1N/UJl1zXcRyX5E3g=";
            };
            buildInputs = with pkgs; [ ncurses fzf ];
            installPhase = ''
              runHook preInstall
              mkdir -p $out/bin
              install -Dm755 sniffert $out/bin/sniffert
              runHook postInstall
            '';
            meta = {
              description =
                "Terminal-based disk analyzer inspired by SpaceSniffer, written in Fortran";
              homepage = "https://github.com/FortranGoingOnForty/sniffert";
              license = pkgs.lib.licenses.mit;
            };
          };

          # ============ FORTRAN (CMAKE) PACKAGES ============

          fortty = pkgs.stdenv.mkDerivation {
            pname = "fortty";
            version = "0.1.5";
            src = pkgs.fetchFromGitHub {
              owner = "FortranGoingOnForty";
              repo = "fortty";
              rev = "v0.1.5";
              hash = "sha256-MHK61ZPFqBu0y/d7qpxaU8AvopgLeCpPmWNkjjo6WoI=";
            };
            nativeBuildInputs = [ pkgs.cmake pkgs.gfortran ];
            buildInputs = with pkgs; [ glfw freetype fontconfig ];
            buildPhase = ''
              cmake -B build -DCMAKE_BUILD_TYPE=Release
              cmake --build build
            '';
            installPhase = ''
              runHook preInstall
              mkdir -p $out/bin
              install -Dm755 build/fortty $out/bin/fortty
              runHook postInstall
            '';
            meta = {
              description =
                "GPU-accelerated terminal emulator written in Fortran";
              homepage = "https://github.com/FortranGoingOnForty/fortty";
              license = pkgs.lib.licenses.mit;
            };
          };

          # ============ C PACKAGES ============

          gitswitcher = mkCMakePackage {
            pname = "gitswitcher";
            version = "1.1.4";
            src = pkgs.fetchFromGitHub {
              owner = "tenseleyFlow";
              repo = "gitswitchC";
              rev = "v1.1.4";
              hash = "sha256-CXKB6tBO6Wwkhs6hmfWxLX1CI7MSbUCA6XWijHPTGxk=";
            };
            buildInputs = with pkgs; [ git openssh openssl ];
            makeFlags = [ "BUILD_TYPE=release" ];
            installPhase = ''
              runHook preInstall
              mkdir -p $out/bin
              make install DESTDIR=$out PREFIX=""
              runHook postInstall
            '';
            meta = {
              description =
                "Secure Git identity and SSH/GPG key management tool";
              homepage = "https://github.com/tenseleyFlow/gitswitchC";
              license = pkgs.lib.licenses.gpl3Plus;
            };
          };

          gitswitch-c = mkCMakePackage {
            pname = "gitswitch-c";
            version = "1.0.0";
            src = pkgs.fetchFromGitHub {
              owner = "tenseleyFlow";
              repo = "gitswitchC";
              rev = "v1.0.0";
              hash = "sha256-HKi/85QpHZorqLVd9P3GpTiS+LPiKqgpDKQHVC0BY7E=";
            };
            buildInputs = with pkgs; [ git openssh openssl ];
            makeFlags = [ "BUILD_TYPE=release" ];
            installPhase = ''
              runHook preInstall
              mkdir -p $out/bin
              make install DESTDIR=$out PREFIX=""
              runHook postInstall
            '';
            meta = {
              description =
                "Safe Git identity switching with SSH/GPG isolation (C implementation)";
              homepage = "https://github.com/tenseleyFlow/gitswitchC";
              license = pkgs.lib.licenses.gpl3Plus;
            };
          };

          shtick = mkCMakePackage {
            pname = "shtick";
            version = "1.0.0";
            src = pkgs.fetchFromGitHub {
              owner = "tenseleyFlow";
              repo = "shtickC";
              rev = "v1.0.0";
              hash = "sha256-0tXH/HlI0eQBaxyTyn5nlHfUP3JGMdkCWeSVIrm8RQU=";
            };
            installPhase = ''
              runHook preInstall
              mkdir -p $out/bin
              make install DESTDIR=$out PREFIX=""
              runHook postInstall
            '';
            meta = {
              description =
                "Shell configuration manager with support for 16 different shells";
              homepage = "https://github.com/tenseleyFlow/shtickC";
              license = pkgs.lib.licenses.mit;
            };
          };

          wmswitch = mkCMakePackage {
            pname = "wmswitch";
            version = "0.1.0";
            src = pkgs.fetchFromGitHub {
              owner = "tenseleyFlow";
              repo = "wmswitch";
              rev = "v0.1.0";
              hash = "sha256-Q8DWgSejuaFMfroFXWKURT0zE8V0Qo3yRIHxIyAuTSw=";
            };
            buildPhase = "make release";
            installPhase = ''
              runHook preInstall
              mkdir -p $out/bin
              install -Dm755 wmswitch $out/bin/wmswitch
              runHook postInstall
            '';
            meta = {
              description =
                "Unified configuration manager for tiling window managers";
              homepage = "https://github.com/tenseleyFlow/wmswitch";
              license = pkgs.lib.licenses.mit;
            };
          };

          # ============ PYTHON PACKAGES ============

          spotify-cue = mkPythonPackage {
            pname = "spotify-cue";
            version = "1.0.0";
            src = pkgs.fetchFromGitHub {
              owner = "notvox";
              repo = "cue";
              rev = "v1.0.0";
              hash = "sha256-XavAU8mbOJHUzYjowwsQaXy3n/4FTey0uX5+8OzEFOg=";
            };
            propagatedBuildInputs = with pkgs.python3Packages; [
              click
              requests
              flask
              spotipy
              schedule
            ];
            meta = {
              description =
                "Unified CLI Spotify controller with intelligent session management";
              homepage = "https://github.com/notvox/cue";
              license = pkgs.lib.licenses.mit;
            };
          };

          waveterm-vis = mkPythonPackage {
            pname = "waveterm-vis";
            version = "0.6.7";
            src = pkgs.fetchFromGitHub {
              owner = "tree3stan-chord";
              repo = "waveterm";
              rev = "v0.6.7";
              hash = "sha256-CxAZCT36KNd+kyJgbTnl4KqE4Kh41yWB/OSOSk7vOtI=";
            };
            propagatedBuildInputs = with pkgs.python3Packages; [
              numpy
              rich
              textual
              click
              pydantic
              toml
            ];
            meta = {
              description =
                "Modern terminal-based music visualizer with ASCII art effects";
              homepage = "https://github.com/tree3stan-chord/waveterm";
              license = pkgs.lib.licenses.mit;
            };
          };

          wezztershier = mkPythonPackage {
            pname = "wezztershier";
            version = "0.2.0";
            src = pkgs.fetchFromGitHub {
              owner = "tenseleyFlow";
              repo = "wezztershier";
              rev = "v0.2.0";
              hash = "sha256-vx/iLDn9x6sDoXI/ZsymJ5SVIzmQPzPJpevu6uTM0Yc=";
            };
            propagatedBuildInputs = with pkgs.python3Packages; [ pyqt6 ];
            meta = {
              description =
                "GUI tuner for WezTerm configuration using static decorators";
              homepage = "https://github.com/tenseleyFlow/wezztershier";
              license = pkgs.lib.licenses.mit;
            };
          };

          # Default package
          default = self.packages.${system}.fackr;
        };

        # Overlay for easy integration
        overlays.default = final: prev: self.packages.${system};
      }) // {
        # NixOS module for easy installation
        nixosModules.default = { config, lib, pkgs, ... }: {
          options.programs.mfwolffe-packages = {
            enable = lib.mkEnableOption "mfwolffe's packages";
            packages = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "List of packages to install";
              example = [ "fackr" "fortress" "parrot-cli" ];
            };
          };

          config = lib.mkIf config.programs.mfwolffe-packages.enable {
            environment.systemPackages = map (name:
              self.packages.${pkgs.stdenv.hostPlatform.system}.${name})
              config.programs.mfwolffe-packages.packages;
          };
        };
      };
}
