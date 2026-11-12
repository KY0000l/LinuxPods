{
  lib,
  stdenv,
  cmake,
  pkg-config,
  openssl,
  libpulseaudio,
  installShellFiles,
  qt6,
}:

stdenv.mkDerivation {
  pname = "linuxpods";
  version = "1.0.2";

  # package.nix lives in the repo root, so build from the checkout itself.
  src = lib.cleanSource ./.;

  # "out" = daemon + CLI, "plasmoid" = KDE Plasma 6 widget (pure QML, no binaries)
  outputs = [
    "out"
    "plasmoid"
  ];

  # CMakeLists.txt is in src/, but it expects ../data and ../plasmoid to exist
  cmakeDir = "../src";

  nativeBuildInputs = [
    cmake
    pkg-config
    installShellFiles,
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    openssl
    libpulseaudio
    qt6.qtbase
    qt6.qtconnectivity # Qt6Bluetooth
  ];

  # The standalone GUI is deprecated upstream in favour of the plasmoid
  cmakeFlags = [ (lib.cmakeBool "LINUXPODS_BUILD_GUI" false) ];

  postInstall = ''
    installManPage data/man/linuxpods-daemon.1 data/man/linuxpods.1

    # Upstream's unit files hardcode /usr/bin
    substituteInPlace \
      $out/share/dbus-1/services/io.github.Explor3Universe.LinuxPods.service \
      $out/lib/systemd/user/linuxpods-daemon.service \
      --replace-fail /usr/bin/linuxpods-daemon $out/bin/linuxpods-daemon

    moveToOutput share/plasma "$plasmoid"
  '';

  meta = {
    description = "AirPods support for Linux: battery, noise control and ear detection, with a KDE Plasma 6 widget";
    homepage = "https://github.com/Explor3Universe/LinuxPods";
    license = with lib.licenses; [
      gpl3Plus
      mit # bundled qr-code-generator
    ];
    platforms = lib.platforms.linux;
    mainProgram = "linuxpods";
  };
}
