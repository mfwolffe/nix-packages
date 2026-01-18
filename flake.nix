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

        # Shared source for gardesk suite (monorepo with submodules)
        gardesk-src = pkgs.fetchgit {
          url = "https://github.com/gardesk/gardesk";
          rev = "904650866396df3458cf143dd9bcf1a3bcc06d6f";
          hash = "sha256-dkKtUohIGzl21qLmerqJBhkgZV7NMB3gFGd9/EtiH0s=";
          fetchSubmodules = true;
          name = "gardesk-src";
        };

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
              fortran-fpm build --profile release
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
            nativeBuildInputs = [ pkgs.gnumake pkgs.pkg-config ];
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
              setuptools-scm
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
            version = "1.1.2";
            src = pkgs.fetchFromGitHub {
              owner = "TenseleyFlow";
              repo = "fackr";
              rev = "v1.1.2";
              hash = "sha256-dp1f6wXo+M0HZcOqMnypRjT86Jdgm9PDh/aNHSqvRRI=";
            };
            cargoHash = "sha256-TuVdCLMZuN1DQKg9lMkY4IytrZZEvg26tjm5jW098Co=";
            postInstall = ''
              mkdir -p $out/share/applications
              cat > $out/share/applications/fackr.desktop << EOF
              [Desktop Entry]
              Name=Fackr
              Comment=Terminal text editor written in Rust
              Exec=fackr
              Terminal=true
              Type=Application
              Categories=Development;TextEditor;
              EOF
            '';
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
            postInstall = ''
              mkdir -p $out/share/applications
              cat > $out/share/applications/fussr.desktop << EOF
              [Desktop Entry]
              Name=Fussr
              Comment=Git staging TUI tool
              Exec=fussr
              Terminal=true
              Type=Application
              Categories=Development;RevisionControl;
              EOF
            '';
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
            buildInputs = with pkgs; [
              wayland
              libxkbcommon
              libGL
              xorg.libX11
              xorg.libXcursor
              xorg.libXi
              xorg.libXrandr
            ];
            nativeBuildInputs = with pkgs; [ makeWrapper ];
            postInstall = ''
              mv $out/bin/wezztershier $out/bin/wezzterrust
              wrapProgram $out/bin/wezzterrust \
                --prefix LD_LIBRARY_PATH : ${
                  pkgs.lib.makeLibraryPath [
                    pkgs.wayland
                    pkgs.libxkbcommon
                    pkgs.libGL
                  ]
                }
              mkdir -p $out/share/applications
              cat > $out/share/applications/wezzterrust.desktop << EOF
              [Desktop Entry]
              Name=WezzteRust
              Comment=High-performance Rust GUI tuner for WezTerm configuration
              Exec=wezzterrust
              Terminal=false
              Type=Application
              Categories=Settings;TerminalEmulator;
              EOF
            '';
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
              mkdir -p $out/share/applications
              cat > $out/share/applications/eyescore.desktop << EOF
              [Desktop Entry]
              Name=Eyescore
              Comment=Professional CLI Music Notation System
              Exec=eyescore
              Terminal=true
              Type=Application
              Categories=Audio;Music;
              EOF
            '';
            meta = {
              description =
                "Professional CLI Music Notation System - colorized TUI score engraver";
              homepage = "https://github.com/tree3stan-chord/score";
              license = pkgs.lib.licenses.mit;
            };
          };

          arco = mkRustPackage {
            pname = "arco";
            version = "0.4.0";
            src = pkgs.fetchFromGitHub {
              owner = "tree3stan-chord";
              repo = "arcorrust";
              rev = "v0.4.0";
              hash = "sha256-f4i7NHcN9adtVvu4clTMMR1RKL78aZDdPrNw893+PYQ=";
            };
            cargoHash = "sha256-n9drDijBpxzpBqus9zRSRTKDCSe61HBpEOPiKH63KPw=";
            buildInputs = with pkgs; [ alsa-lib ];
            postInstall = ''
              mkdir -p $out/share/applications
              cat > $out/share/applications/arco.desktop << EOF
              [Desktop Entry]
              Name=Arco
              Comment=Terminal-based virtual instrument with real-time synthesis
              Exec=arco
              Terminal=true
              Type=Application
              Categories=Audio;Music;
              EOF
            '';
            meta = {
              description =
                "Terminal-based virtual instrument with real-time synthesis and visualization";
              homepage = "https://github.com/tree3stan-chord/arcorrust";
              license = pkgs.lib.licenses.mit;
            };
          };

          hyprkvm = mkRustPackage {
            pname = "hyprkvm";
            version = "0.6.6";
            src = pkgs.fetchFromGitHub {
              owner = "tenseleyFlow";
              repo = "hyprKVM";
              rev = "v0.6.6";
              hash = "sha256-bxzHVAdGKSpBuCUrynzBJL6zOUk0m5Q6b3RwZcswWyE=";
            };
            cargoHash = "sha256-yoYaamk7yZxTB2WaxrJZXe9Gtlp/Kt52MTukSw3gxzo=";
            buildInputs = with pkgs; [ wayland wayland-protocols libxkbcommon ];
            postInstall = ''
              mkdir -p $out/share/applications
              cat > $out/share/applications/hyprkvm.desktop << EOF
              [Desktop Entry]
              Name=HyprKVM
              Comment=Hyprland-native software KVM switch
              Exec=hyprkvm daemon
              Terminal=false
              Type=Application
              Categories=Utility;System;
              EOF
            '';
            meta = {
              description =
                "Hyprland-native software KVM switch for seamless keyboard/mouse sharing";
              homepage = "https://github.com/tenseleyFlow/hyprKVM";
              license = pkgs.lib.licenses.mit;
            };
          };

          firp = mkRustPackage {
            pname = "firp";
            version = "0.2.0";
            src = pkgs.fetchFromGitHub {
              owner = "FortranGoingOnForty";
              repo = "firp";
              rev = "v0.2.0";
              hash = "sha256-gh1COa4xy50KwhjML9t5d5k4LpWFyC7gJiYYB3kbDM0=";
            };
            cargoHash = "sha256-ihKVw2B4+GsKasbdlQodqrSpj2J5j1tQSr2WRH3DG3Y=";
            postInstall = ''
              mkdir -p $out/share/applications
              cat > $out/share/applications/firp.desktop << EOF
              [Desktop Entry]
              Name=Firp
              Comment=Modern Fortran Interpreter with JIT compilation
              Exec=firp
              Terminal=true
              Type=Application
              Categories=Development;IDE;
              EOF
            '';
            meta = {
              description =
                "A Modern Fortran Interpreter with REPL, debugger, and JIT compilation";
              homepage = "https://github.com/FortranGoingOnForty/firp";
              license = pkgs.lib.licenses.mit;
            };
          };

          # ============ GARDESK SUITE ============
          # Modular X11 desktop environment - https://gar.dev
          # NOTE: Uses fetchgit with submodules for path dependencies

          # gar: Tiling window manager with Lua config
          gar = pkgs.rustPlatform.buildRustPackage {
            pname = "gar";
            version = "0.1.0";
            src = gardesk-src;
            sourceRoot = "gardesk-src/gar";
            cargoHash = "sha256-UCg3kaKCi8L+Tr//arjMpesAtxNgDhSnyGdwUddNKnU=";

            nativeBuildInputs = with pkgs; [ pkg-config makeWrapper ];
            buildInputs = with pkgs; [
              xorg.libxcb
              xorg.libX11
              xorg.libXrandr
            ];

            cargoBuildFlags = [ "-p" "gar" "-p" "garctl" ];

            postInstall = ''
              # Install session wrapper script
              mkdir -p $out/share/gar
              install -Dm755 gar-session.sh $out/share/gar/gar-session.sh

              # Wrap session script with runtime dependencies in PATH
              makeWrapper $out/share/gar/gar-session.sh $out/bin/gar-session \
                --prefix PATH : ${lib.makeBinPath [ pkgs.picom pkgs.systemd pkgs.dbus ]} \
                --set GAR_BIN "$out/bin/gar"

              # XSession entry uses the wrapped session script (not gar directly)
              mkdir -p $out/share/xsessions
              cat > $out/share/xsessions/gar.desktop << EOF
              [Desktop Entry]
              Name=gar
              Comment=gar tiling window manager
              Exec=$out/bin/gar-session
              Type=XSession
              DesktopNames=gar
              EOF

              # Install systemd user target for gar session
              mkdir -p $out/lib/systemd/user
              cat > $out/lib/systemd/user/gar-session.target << EOF
              [Unit]
              Description=gar window manager session
              Documentation=man:systemd.special(7)
              BindsTo=graphical-session.target
              Wants=graphical-session-pre.target
              After=graphical-session-pre.target
              EOF
            '';

            passthru = {
              providedSessions = [ "gar" ];
              optionalDependencies = [ pkgs.picom ];
            };

            meta = {
              description = "Tiling window manager with Lua configuration and smart splits";
              homepage = "https://github.com/gardesk/gar";
              license = pkgs.lib.licenses.mit;
            };
          };

          # garbar: Status bar with Cairo/Pango rendering
          garbar = pkgs.rustPlatform.buildRustPackage {
            pname = "garbar";
            version = "0.1.0";
            src = gardesk-src;
            sourceRoot = "gardesk-src/garbar";
            cargoHash = "sha256-p0mJxoKV1ozS2kbzvznu0S3RmaUPAIIr7JhsVD4B4wM=";

            nativeBuildInputs = with pkgs; [ pkg-config ];
            buildInputs = with pkgs; [
              xorg.libxcb
              xorg.libX11
              xorg.libXrandr
              xorg.libXfixes
              cairo
              pango
              glib
              harfbuzz
              freetype
              fontconfig
            ];

            cargoBuildFlags = [ "-p" "garbar" "-p" "garbarctl" ];

            meta = {
              description = "Status bar with Cairo/Pango rendering for the gar desktop suite";
              homepage = "https://github.com/gardesk/garbar";
              license = pkgs.lib.licenses.mit;
            };
          };

          # garbg: Wallpaper daemon with animation support
          garbg = pkgs.rustPlatform.buildRustPackage {
            pname = "garbg";
            version = "0.1.0";
            src = gardesk-src;
            sourceRoot = "gardesk-src/garbg";
            cargoHash = "sha256-PqsmAJaBL1cUaiE5zytExSBtBbhA2kGbNhG4i+5Nkg8=";

            # Use ffmpeg_7 (not ffmpeg-full/8.0) - avfft.h removed in FFmpeg 8.0
            nativeBuildInputs = with pkgs; [ pkg-config clang llvmPackages.libclang ];
            buildInputs = with pkgs; [
              xorg.libxcb
              xorg.libX11
              xorg.libXrandr
              openssl
              ffmpeg_7
            ];

            # Required for ffmpeg-sys-next bindgen
            LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";

            # Comprehensive bindgen fix for Nix - expose gcc-wrapper flags to libclang
            # See: https://hoverbear.org/blog/rust-bindgen-in-nix/
            preBuild = ''
              export BINDGEN_EXTRA_CLANG_ARGS="$(< ${pkgs.stdenv.cc}/nix-support/libc-crt1-cflags) \
                $(< ${pkgs.stdenv.cc}/nix-support/libc-cflags) \
                $(< ${pkgs.stdenv.cc}/nix-support/cc-cflags) \
                ${lib.optionalString pkgs.stdenv.cc.isGNU "-isystem ${pkgs.stdenv.cc.cc}/include/c++/${lib.getVersion pkgs.stdenv.cc.cc} -isystem ${pkgs.stdenv.cc.cc}/include/c++/${lib.getVersion pkgs.stdenv.cc.cc}/${pkgs.stdenv.hostPlatform.config} -idirafter ${pkgs.stdenv.cc.cc}/lib/gcc/${pkgs.stdenv.hostPlatform.config}/${lib.getVersion pkgs.stdenv.cc.cc}/include"} \
                -I${pkgs.ffmpeg_7.dev}/include"
            '';

            postInstall = ''
              # Install systemd user service
              mkdir -p $out/lib/systemd/user
              cat > $out/lib/systemd/user/garbg.service << EOF
              [Unit]
              Description=garbg wallpaper daemon
              Documentation=https://gar.dev
              After=graphical-session.target
              PartOf=graphical-session.target

              [Service]
              Type=simple
              ExecStart=$out/bin/garbg daemon
              Restart=on-failure
              RestartSec=3

              [Install]
              WantedBy=graphical-session.target
              EOF
            '';

            meta = {
              description = "Wallpaper daemon with animation and slideshow support";
              homepage = "https://github.com/gardesk/garbg";
              license = pkgs.lib.licenses.mit;
            };
          };

          # garshot: Screenshot utility with blur selection overlay
          garshot = pkgs.rustPlatform.buildRustPackage {
            pname = "garshot";
            version = "0.1.0";
            src = gardesk-src;
            sourceRoot = "gardesk-src/garshot";
            cargoHash = "sha256-cg8ACAkxRhKfklzHYLOgD44Wc88j5UaQ7qHLzYw+vW0=";

            nativeBuildInputs = with pkgs; [ pkg-config ];
            buildInputs = with pkgs; [
              xorg.libxcb
              xorg.libX11
              xorg.libXrandr
              xorg.libXfixes
              cairo
              pango
              glib
              harfbuzz
              freetype
              fontconfig
            ];

            cargoBuildFlags = [ "-p" "garshot" "-p" "garshotctl" ];

            postInstall = ''
              mkdir -p $out/share/applications
              cat > $out/share/applications/garshot.desktop << EOF
              [Desktop Entry]
              Name=Garshot
              Comment=Screenshot utility with blur selection overlay
              Exec=$out/bin/garshot select
              Terminal=false
              Type=Application
              Categories=Utility;Graphics;
              EOF
            '';

            meta = {
              description = "Screenshot utility with interactive blur selection overlay";
              homepage = "https://github.com/gardesk/garshot";
              license = pkgs.lib.licenses.mit;
            };
          };

          # garlock: Screen locker with PAM authentication
          garlock = pkgs.rustPlatform.buildRustPackage {
            pname = "garlock";
            version = "0.1.0";
            src = gardesk-src;
            sourceRoot = "gardesk-src/garlock";
            cargoHash = "sha256-x98QlMesEEItBq7gDHxuHEmVzz3pVUHqXXgCQNaoipw=";

            nativeBuildInputs = with pkgs; [ pkg-config clang llvmPackages.libclang ];
            buildInputs = with pkgs; [
              xorg.libxcb
              xorg.libX11
              xorg.libXrandr
              cairo
              pango
              glib
              harfbuzz
              freetype
              fontconfig
              pam
              libxkbcommon
            ];

            # Required for pam-sys bindgen
            LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";

            preBuild = ''
              export BINDGEN_EXTRA_CLANG_ARGS="$(< ${pkgs.stdenv.cc}/nix-support/libc-crt1-cflags) \
                $(< ${pkgs.stdenv.cc}/nix-support/libc-cflags) \
                $(< ${pkgs.stdenv.cc}/nix-support/cc-cflags) \
                ${lib.optionalString pkgs.stdenv.cc.isGNU "-isystem ${pkgs.stdenv.cc.cc}/include/c++/${lib.getVersion pkgs.stdenv.cc.cc} -isystem ${pkgs.stdenv.cc.cc}/include/c++/${lib.getVersion pkgs.stdenv.cc.cc}/${pkgs.stdenv.hostPlatform.config} -idirafter ${pkgs.stdenv.cc.cc}/lib/gcc/${pkgs.stdenv.hostPlatform.config}/${lib.getVersion pkgs.stdenv.cc.cc}/include"}"
            '';

            meta = {
              description = "Screen locker with PAM authentication for the gar desktop suite";
              homepage = "https://github.com/gardesk/garlock";
              license = pkgs.lib.licenses.mit;
            };
          };

          # garlaunch: Application launcher (needs full tree for gartk path deps)
          garlaunch = pkgs.stdenv.mkDerivation {
            pname = "garlaunch";
            version = "0.2.0";
            src = gardesk-src;

            nativeBuildInputs = with pkgs; [ pkg-config rustPlatform.cargoSetupHook cargo rustc ];
            buildInputs = with pkgs; [
              xorg.libxcb
              xorg.libX11
              xorg.libXrandr
              cairo
              pango
              glib
              harfbuzz
              freetype
              fontconfig
            ];

            cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
              inherit (pkgs.stdenv) system;
              src = gardesk-src;
              sourceRoot = "gardesk-src/garlaunch";
              hash = "sha256-kSyQSAIynkWATdQX36pBBvl5Pd/NbxaSF/Msalp9Wao=";
            };
            cargoRoot = "garlaunch";

            buildPhase = ''
              cd garlaunch
              cargo build --release --offline -p garlaunch -p garlaunchctl
            '';

            installPhase = ''
              mkdir -p $out/bin $out/share/applications
              cp target/release/garlaunch $out/bin/
              cp target/release/garlaunchctl $out/bin/
              cat > $out/share/applications/garlaunch.desktop << EOF
              [Desktop Entry]
              Name=Garlaunch
              Comment=Application launcher with fuzzy search
              Exec=$out/bin/garlaunch
              Terminal=false
              Type=Application
              Categories=Utility;
              EOF
            '';

            meta = {
              description = "Application launcher with fuzzy search for the gar desktop suite";
              homepage = "https://github.com/gardesk/garlaunch";
              license = pkgs.lib.licenses.mit;
            };
          };

          # garclip: Clipboard manager (needs full tree for gartk path deps)
          garclip = pkgs.stdenv.mkDerivation {
            pname = "garclip";
            version = "0.1.0";
            src = gardesk-src;

            nativeBuildInputs = with pkgs; [ pkg-config rustPlatform.cargoSetupHook cargo rustc ];
            buildInputs = with pkgs; [
              xorg.libxcb
              xorg.libX11
              xorg.libXrandr
              xorg.libXfixes
              cairo
              pango
              glib
              harfbuzz
              freetype
              fontconfig
            ];

            cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
              inherit (pkgs.stdenv) system;
              src = gardesk-src;
              sourceRoot = "gardesk-src/garclip";
              hash = "sha256-sL0h8ektkvAQjbBohKG+YDjSCSHogyVT1q16jW3VJHI=";
            };
            cargoRoot = "garclip";

            buildPhase = ''
              cd garclip
              cargo build --release --offline -p garclip -p garclipctl -p garclip-picker
            '';

            installPhase = ''
              mkdir -p $out/bin $out/share/applications
              cp target/release/garclip $out/bin/
              cp target/release/garclipctl $out/bin/
              cp target/release/garclip-picker $out/bin/
              cat > $out/share/applications/garclip.desktop << EOF
              [Desktop Entry]
              Name=Garclip
              Comment=Clipboard manager with history
              Exec=$out/bin/garclip-picker
              Terminal=false
              Type=Application
              Categories=Utility;
              EOF

              # Install systemd user service
              mkdir -p $out/lib/systemd/user
              cat > $out/lib/systemd/user/garclip.service << EOF
              [Unit]
              Description=garclip clipboard manager
              Documentation=https://gar.dev
              PartOf=graphical-session.target
              After=graphical-session.target

              [Service]
              Type=simple
              ExecStart=$out/bin/garclip daemon --foreground
              ExecReload=/bin/kill -HUP \$MAINPID
              Restart=on-failure
              RestartSec=1

              [Install]
              WantedBy=graphical-session.target
              EOF
            '';

            meta = {
              description = "Clipboard manager with history for the gar desktop suite";
              homepage = "https://github.com/gardesk/garclip";
              license = pkgs.lib.licenses.mit;
            };
          };

          # gardm: Display manager with PAM and systemd integration
          gardm = pkgs.rustPlatform.buildRustPackage {
            pname = "gardm";
            version = "0.1.0";
            src = gardesk-src;
            sourceRoot = "gardesk-src/gardm";
            cargoHash = "sha256-cNKo8ZkPecEXHAtJsqJiFiYHb/43rvZoKRT+MJ/JgDc=";

            nativeBuildInputs = with pkgs; [ pkg-config clang llvmPackages.libclang ];
            buildInputs = with pkgs; [
              xorg.libxcb
              xorg.libX11
              xorg.libXrandr
              xorg.xorgserver
              cairo
              pango
              glib
              harfbuzz
              freetype
              fontconfig
              pam
            ];

            # Patch hardcoded /usr/bin/Xorg path for NixOS
            postPatch = ''
              substituteInPlace gardmd/src/x11.rs \
                --replace-fail '"/usr/bin/Xorg"' '"${pkgs.xorg.xorgserver}/bin/Xorg"'
            '';

            # Required for pam-sys bindgen
            LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";

            preBuild = ''
              export BINDGEN_EXTRA_CLANG_ARGS="$(< ${pkgs.stdenv.cc}/nix-support/libc-crt1-cflags) \
                $(< ${pkgs.stdenv.cc}/nix-support/libc-cflags) \
                $(< ${pkgs.stdenv.cc}/nix-support/cc-cflags) \
                ${lib.optionalString pkgs.stdenv.cc.isGNU "-isystem ${pkgs.stdenv.cc.cc}/include/c++/${lib.getVersion pkgs.stdenv.cc.cc} -isystem ${pkgs.stdenv.cc.cc}/include/c++/${lib.getVersion pkgs.stdenv.cc.cc}/${pkgs.stdenv.hostPlatform.config} -idirafter ${pkgs.stdenv.cc.cc}/lib/gcc/${pkgs.stdenv.hostPlatform.config}/${lib.getVersion pkgs.stdenv.cc.cc}/include"}"
            '';

            cargoBuildFlags = [ "-p" "gardmd" "-p" "gardm-greeter" ];

            postInstall = ''
              mkdir -p $out/share/gardm/pam.d
              cat > $out/share/gardm/pam.d/gardm << EOF
              #%PAM-1.0
              auth       include      login
              account    include      login
              password   include      login
              session    include      login
              EOF

              # Install systemd system service
              mkdir -p $out/lib/systemd/system
              cat > $out/lib/systemd/system/gardm.service << EOF
              [Unit]
              Description=gar Display Manager
              Documentation=https://gar.dev
              After=systemd-user-sessions.service getty@tty1.service plymouth-quit.service systemd-logind.service
              Conflicts=getty@tty1.service
              PartOf=graphical.target
              StartLimitIntervalSec=30
              StartLimitBurst=2

              [Service]
              Type=notify
              ExecStart=$out/bin/gardmd
              ExecReload=/bin/kill -HUP \$MAINPID
              Restart=always
              RestartSec=1
              PrivateTmp=no

              [Install]
              Alias=display-manager.service
              EOF
            '';

            passthru.providedSessions = [ "gar" ];

            meta = {
              description = "Display manager with graphical greeter for the gar desktop suite";
              homepage = "https://github.com/gardesk/gardm";
              license = pkgs.lib.licenses.mit;
            };
          };

          # ============ GO PACKAGES ============

          parrot-cli = mkGoPackage {
            pname = "parrot-cli";
            version = "1.9.0";
            src = pkgs.fetchFromGitHub {
              owner = "tenseleyFlow";
              repo = "parrot";
              rev = "v1.9.0";
              hash = "sha256-OzkA9Dw2ZO1CahMrhnAlYpIW3jrSGEu8Ld0cFMxUNTs=";
            };
            vendorHash = "sha256-kT0CKC19lvYjNzUS+wUFWTA1IJogiQv/Lf9DQeh30FA=";
            postInstall = ''
              mkdir -p $out/share/parrot
              install -Dm644 $src/parrot-hook.sh $out/share/parrot/parrot-hook.sh
              install -Dm644 $src/parrot-hook.fish $out/share/parrot/parrot-hook.fish
              mkdir -p $out/share/applications
              cat > $out/share/applications/parrot.desktop << EOF
              [Desktop Entry]
              Name=Parrot
              Comment=Intelligent roasts of failed commands
              Exec=parrot
              Terminal=true
              Type=Application
              Categories=Development;Utility;
              EOF
            '';
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
            postInstall = ''
              mkdir -p $out/share/applications
              cat > $out/share/applications/shellp.desktop << EOF
              [Desktop Entry]
              Name=Shellp
              Comment=Development note-taking companion for shell commands
              Exec=shellp
              Terminal=true
              Type=Application
              Categories=Development;Utility;
              EOF
            '';
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
            buildInputs = with pkgs; [ fzf git ncurses ];
            installPhase = ''
              runHook preInstall
              mkdir -p $out/bin $out/share/fortress $out/share/applications
              install -Dm755 build/gfortran_*/app/fortress $out/bin/fortress-bin
              install -Dm644 fortress.sh $out/share/fortress/fortress.sh
              install -Dm644 fortress.fish $out/share/fortress/fortress.fish
              cat > $out/share/applications/fortress.desktop << EOF
              [Desktop Entry]
              Name=Fortress
              Comment=Command-line file explorer written in Fortran
              Exec=fortress-bin
              Terminal=true
              Type=Application
              Categories=System;FileManager;
              EOF
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
            version = "0.9.6";
            src = pkgs.fetchFromGitHub {
              owner = "FortranGoingOnForty";
              repo = "facsimile";
              rev = "v0.9.6";
              hash = "sha256-Z4OxRYyado1SXRdqmFQwJGbixlsjUXHJOLBr8SWzrOw=";
            };
            installPhase = ''
              runHook preInstall
              mkdir -p $out/bin $out/share/applications
              fac_binary=$(find build -name "fac" -type f)
              install -Dm755 "$fac_binary" $out/bin/fac
              ln -s fac $out/bin/facsimile
              cat > $out/share/applications/facsimile.desktop << EOF
              [Desktop Entry]
              Name=Facsimile
              Comment=Terminal text editor with VSCode-style keybindings
              Exec=fac
              Terminal=true
              Type=Application
              Categories=Development;TextEditor;
              EOF
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
            version = "1.0.1";
            src = pkgs.fetchFromGitHub {
              owner = "FortranGoingOnForty";
              repo = "fortsh";
              rev = "v1.0.1";
              hash = "sha256-ijzzh2rhNrbfVpwvkr3ZFMNa+uMWUwp6vjduAHAI6fM=";
            };
            buildPhase = "make release";
            installPhase = ''
              runHook preInstall
              mkdir -p $out/bin $out/share/applications
              install -Dm755 bin/fortsh $out/bin/fortsh
              cat > $out/share/applications/fortsh.desktop << EOF
              [Desktop Entry]
              Name=Fortsh
              Comment=Modern Fortran shell with AST-based parsing
              Exec=fortsh
              Terminal=true
              Type=Application
              Categories=System;TerminalEmulator;
              EOF
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
              mkdir -p $out/bin $out/share/applications
              install -Dm755 bin/fit $out/bin/fit
              cat > $out/share/applications/fit.desktop << EOF
              [Desktop Entry]
              Name=Fit
              Comment=Terminal-based merge conflict resolver
              Exec=fit
              Terminal=true
              Type=Application
              Categories=Development;RevisionControl;
              EOF
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
              mkdir -p $out/bin $out/share/applications
              install -Dm755 fuss $out/bin/fuss
              cat > $out/share/applications/fuss.desktop << EOF
              [Desktop Entry]
              Name=Fuss
              Comment=Tree utility for dirty git files
              Exec=fuss
              Terminal=true
              Type=Application
              Categories=Development;RevisionControl;
              EOF
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
              mkdir -p $out/bin $out/share/applications
              install -Dm755 ferp $out/bin/ferp
              cat > $out/share/applications/ferp.desktop << EOF
              [Desktop Entry]
              Name=Ferp
              Comment=GNU grep clone written in Fortran
              Exec=ferp
              Terminal=true
              Type=Application
              Categories=Utility;TextTools;
              EOF
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
              mkdir -p $out/bin $out/share/applications
              install -Dm755 build/bin/fortbite $out/bin/fortbite
              cat > $out/share/applications/fortbite.desktop << EOF
              [Desktop Entry]
              Name=Fortbite
              Comment=High-precision mathematical calculator
              Exec=fortbite
              Terminal=true
              Type=Application
              Categories=Education;Science;Math;Calculator;
              EOF
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
              mkdir -p $out/bin $out/share/applications
              install -Dm755 sniffert $out/bin/sniffert
              cat > $out/share/applications/sniffert.desktop << EOF
              [Desktop Entry]
              Name=Sniffert
              Comment=Terminal-based disk analyzer
              Exec=sniffert
              Terminal=true
              Type=Application
              Categories=System;Utility;FileTools;
              EOF
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
            version = "0.1.6";
            src = pkgs.fetchFromGitHub {
              owner = "FortranGoingOnForty";
              repo = "fortty";
              rev = "v0.1.6";
              hash = "sha256-jzPYsCZuXAkAbeZKYfx+VLT4NFovsZJ2slkefwn9auA=";
            };
            nativeBuildInputs = [ pkgs.cmake pkgs.gfortran pkgs.pkg-config ];
            buildInputs = with pkgs; [ glfw freetype fontconfig ];
            dontUseCmakeConfigure = true;
            buildPhase = ''
              cmake -B build -DCMAKE_BUILD_TYPE=Release
              cmake --build build
            '';
            installPhase = ''
              runHook preInstall
              mkdir -p $out/bin $out/share/applications
              install -Dm755 build/fortty $out/bin/fortty
              cat > $out/share/applications/fortty.desktop << EOF
              [Desktop Entry]
              Name=Fortty
              Comment=GPU-accelerated terminal emulator written in Fortran
              Exec=fortty
              Terminal=false
              Type=Application
              Categories=System;TerminalEmulator;
              EOF
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
            version = "1.1.9";
            src = pkgs.fetchFromGitHub {
              owner = "tenseleyFlow";
              repo = "gitswitchC";
              rev = "v1.1.9";
              hash = "sha256-NMieHzCZJ71LvuFhVRq4B+5RIbMtvZlHOYS4rLOXCJ0=";
            };
            buildInputs = with pkgs; [ git openssh openssl ];
            makeFlags = [ "BUILD_TYPE=release" "VERSION=1.1.9" "COMMIT=b9a8f5e" ];
            installPhase = ''
              runHook preInstall
              mkdir -p $out/bin $out/share/applications
              install -m 755 build/bin/gitswitch $out/bin/gitswitch
              cat > $out/share/applications/gitswitcher.desktop << EOF
              [Desktop Entry]
              Name=GitSwitcher
              Comment=Secure Git identity and SSH/GPG key management
              Exec=gitswitch
              Terminal=true
              Type=Application
              Categories=Development;RevisionControl;
              EOF
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
            version = "1.1.9";
            src = pkgs.fetchFromGitHub {
              owner = "tenseleyFlow";
              repo = "gitswitchC";
              rev = "v1.1.9";
              hash = "sha256-NMieHzCZJ71LvuFhVRq4B+5RIbMtvZlHOYS4rLOXCJ0=";
            };
            buildInputs = with pkgs; [ git openssh openssl ];
            makeFlags = [ "BUILD_TYPE=release" "VERSION=1.1.9" "COMMIT=b9a8f5e" ];
            installPhase = ''
              runHook preInstall
              mkdir -p $out/bin $out/share/applications
              install -m 755 build/bin/gitswitch $out/bin/gitswitch
              cat > $out/share/applications/gitswitch-c.desktop << EOF
              [Desktop Entry]
              Name=GitSwitch-C
              Comment=Safe Git identity switching with SSH/GPG isolation
              Exec=gitswitch
              Terminal=true
              Type=Application
              Categories=Development;RevisionControl;
              EOF
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
            version = "1.0.1";
            src = pkgs.fetchFromGitHub {
              owner = "tenseleyFlow";
              repo = "shtickC";
              rev = "v1.0.1";
              hash = "sha256-KyCy5lUTwcgXpPYHLn0fnJOoJUN0hQuUBK4k1GJ87kM=";
            };
            installPhase = ''
              runHook preInstall
              mkdir -p $out/bin $out/share/applications
              install -Dm755 shtick $out/bin/shtick
              cat > $out/share/applications/shtick.desktop << EOF
              [Desktop Entry]
              Name=Shtick
              Comment=Shell configuration manager for 16 different shells
              Exec=shtick
              Terminal=true
              Type=Application
              Categories=Settings;System;
              EOF
              runHook postInstall
            '';
            meta = {
              description =
                "Shell configuration manager with support for 16 different shells";
              homepage = "https://github.com/tenseleyFlow/shtickC";
              license = pkgs.lib.licenses.mit;
            };
          };

          wmswitch = let
            tomlc99 = pkgs.fetchFromGitHub {
              owner = "cktan";
              repo = "tomlc99";
              rev = "26b9c1ea770dab2378e5041b695d24ccebe58a7a";
              hash = "sha256-VWdv80klW/Wuf1PhIIoW2hdclMJ8hKmyS/cH4Y4J1AE=";
            };
          in pkgs.stdenv.mkDerivation {
            pname = "wmswitch";
            version = "0.1.0";
            src = pkgs.fetchFromGitHub {
              owner = "tenseleyFlow";
              repo = "wmswitch";
              rev = "v0.1.0";
              hash = "sha256-Q8DWgSejuaFMfroFXWKURT0zE8V0Qo3yRIHxIyAuTSw=";
            };
            nativeBuildInputs = [ pkgs.gnumake ];
            postUnpack = ''
              mkdir -p $sourceRoot/lib
              cp -r ${tomlc99} $sourceRoot/lib/tomlc99
              chmod -R +w $sourceRoot/lib/tomlc99
            '';
            buildPhase = "make release";
            installPhase = ''
              runHook preInstall
              mkdir -p $out/bin $out/share/applications
              install -Dm755 bin/wmswitch $out/bin/wmswitch
              cat > $out/share/applications/wmswitch.desktop << EOF
              [Desktop Entry]
              Name=WMSwitch
              Comment=Unified configuration manager for tiling window managers
              Exec=wmswitch
              Terminal=true
              Type=Application
              Categories=Settings;DesktopSettings;
              EOF
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
            postInstall = ''
              mkdir -p $out/share/applications
              cat > $out/share/applications/spotify-cue.desktop << EOF
              [Desktop Entry]
              Name=Spotify Cue
              Comment=CLI Spotify controller with session management
              Exec=cue
              Terminal=true
              Type=Application
              Categories=Audio;Music;
              EOF
            '';
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
            preBuild = ''
              rm -rf dist
            '';
            propagatedBuildInputs = with pkgs.python3Packages; [
              numpy
              rich
              textual
              click
              pydantic
              toml
            ];
            postInstall = ''
              mkdir -p $out/share/applications
              cat > $out/share/applications/waveterm-vis.desktop << EOF
              [Desktop Entry]
              Name=Waveterm Visualizer
              Comment=Terminal-based music visualizer with ASCII art effects
              Exec=waveterm
              Terminal=true
              Type=Application
              Categories=Audio;Music;
              EOF
            '';
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
            postInstall = ''
              mkdir -p $out/share/applications
              cat > $out/share/applications/wezztershier.desktop << EOF
              [Desktop Entry]
              Name=Wezztershier
              Comment=GUI tuner for WezTerm configuration
              Exec=wezztershier
              Terminal=false
              Type=Application
              Categories=Settings;TerminalEmulator;
              EOF
            '';
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
