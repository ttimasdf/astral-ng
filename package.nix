{
  lib,
  stdenv,
  flutter344,
  rustPlatform,
  fetchFromGitHub,
  makeDesktopItem,
  copyDesktopItems,
  writeText,
  libayatana-appindicator,
  protobuf,
}:

let
  pname = "astral-ng";
  version = "2-unstable-2026-03-17";

  src = lib.cleanSource ./.;

  rustDep = rustPlatform.buildRustPackage {
    inherit pname version;
    src = "${src}/rust";

    cargoHash = "sha256-f1dRD+8hE2QEhBOWi37N9IC/hKQfSNdNdB6j67VpOso=";

    nativeBuildInputs = [
      protobuf
      rustPlatform.bindgenHook
    ];

    passthru.libraryPath = "lib/librust_lib_astral.so";

    meta.platforms = lib.platforms.linux;
  };
in
flutter344.buildFlutterApplication {
  inherit pname version src;

  autoPubspecLock = src + "/pubspec.lock";

  customSourceBuilders = {
    rust_lib_astral =
      { version, src, ... }:
      stdenv.mkDerivation {
        pname = "rust_lib_astral";
        inherit version src;
        inherit (src) passthru;

        postPatch =
          let
            fakeCargokitCmake = writeText "FakeCargokit.cmake" ''
              function(apply_cargokit target manifest_dir lib_name any_symbol_name)
                set("''${target}_cargokit_lib" ${rustDep}/${rustDep.passthru.libraryPath} PARENT_SCOPE)
              endfunction()
            '';
          in
          ''
            cp ${fakeCargokitCmake} rust_builder/cargokit/cmake/cargokit.cmake
          '';

        installPhase = ''
          runHook preInstall

          cp -r . "$out"

          runHook postInstall
        '';
      };
  };

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    copyDesktopItems
  ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    libayatana-appindicator
  ];

  postInstall = lib.optionalString stdenv.hostPlatform.isLinux ''
    mkdir -p $out/share/pixmaps
    cp $out/app/${pname}/data/flutter_assets/assets/logo.png $out/share/pixmaps/astral-ng.png
  '';

  extraWrapProgramArgs = lib.optionalString stdenv.hostPlatform.isLinux ''
    --prefix LD_LIBRARY_PATH : $out/app/${pname}/lib
  '';

  desktopItems = lib.optionals stdenv.hostPlatform.isLinux [
    (makeDesktopItem {
      name = "astral-ng";
      desktopName = "Astral-NG";
      comment = "Astral-NG is an Easytier desktop client";
      exec = "astral %u";
      icon = "astral-ng";
      terminal = false;
      type = "Application";
      categories = [ "Network" ];
      startupNotify = true;
      keywords = [
        "Easytier"
        "VPN"
        "Network"
        "Proxy"
      ];
    })
  ];

  passthru = {
    inherit rustDep;
  };

  meta = with lib; {
    description = "Astral desktop client";
    homepage = "https://github.com/ttimasdf/astral-ng";
    license = licenses.gpl3;
    maintainers = with maintainers; [ ];
    platforms = platforms.linux;
    mainProgram = "astral";
  };
}
