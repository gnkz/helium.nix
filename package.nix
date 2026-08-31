{
  lib,
  stdenv,
  fetchurl,
  addDriverRunpath,
  adwaita-icon-theme,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  coreutils,
  cups,
  dbus,
  expat,
  fontconfig,
  freetype,
  gdk-pixbuf,
  glib,
  gsettings-desktop-schemas,
  gtk3,
  gtk4,
  libdrm,
  libGL,
  libkrb5,
  libpulseaudio,
  libva,
  libx11,
  libxcb,
  libxcomposite,
  libxcursor,
  libxdamage,
  libxext,
  libxfixes,
  libxi,
  libxkbcommon,
  libxrandr,
  libxrender,
  libxscrnsaver,
  libxshmfence,
  libxtst,
  libgbm,
  makeWrapper,
  nspr,
  nss,
  pango,
  patchelf,
  pipewire,
  pciutils,
  qt6,
  snappy,
  systemd,
  vulkan-loader,
  wayland,
  xdg-utils,
  zlib,
}:

let
  release = import ./versions.nix;

  runtimeLibraries = [
    stdenv.cc.cc
    stdenv.cc.libc
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk3
    gtk4
    libdrm
    libGL
    libkrb5
    libpulseaudio
    libva
    libx11
    libxcb
    libxcomposite
    libxcursor
    libxdamage
    libxext
    libxfixes
    libxi
    libxkbcommon
    libxrandr
    libxrender
    libxscrnsaver
    libxshmfence
    libxtst
    libgbm
    nspr
    nss
    pango
    pipewire
    pciutils
    qt6.qtbase
    qt6.qtwayland
    snappy
    systemd
    vulkan-loader
    wayland
    zlib
  ];

  libraryPath =
    lib.makeLibraryPath runtimeLibraries
    + lib.optionalString stdenv.hostPlatform.is64bit (
      ":" + lib.makeSearchPathOutput "lib" "lib64" runtimeLibraries
    );
in
stdenv.mkDerivation {
  pname = "helium-bin";
  inherit (release) version;

  src = fetchurl {
    url = "https://github.com/imputnet/helium-linux/releases/download/${release.version}/helium-${release.version}-x86_64_linux.tar.xz";
    inherit (release) hash;
  };

  sourceRoot = "helium-${release.version}-x86_64_linux";

  strictDeps = true;
  dontConfigure = true;
  dontBuild = true;
  dontPatchELF = true;
  dontStrip = true;

  nativeBuildInputs = [
    makeWrapper
    patchelf
    qt6.wrapQtAppsHook
  ];

  buildInputs = runtimeLibraries ++ [
    adwaita-icon-theme
    gsettings-desktop-schemas
  ];

  dontWrapQtApps = true;

  installPhase = ''
    runHook preInstall

    install -d "$out/bin" "$out/libexec/helium" \
      "$out/share/applications" "$out/share/icons/hicolor/256x256/apps"
    cp -a ./. "$out/libexec/helium/"

    substituteInPlace "$out/libexec/helium/helium-wrapper" \
      --replace-fail 'CHROME_VERSION_EXTRA="custom"' 'CHROME_VERSION_EXTRA="nix"' \
      --replace-fail 'CHROME_WRAPPER="$(readlink -f "$0")"' 'WRAPPER="$(${coreutils}/bin/readlink -f "$0")"' \
      --replace-fail 'HERE="$(dirname "$CHROME_WRAPPER")"' 'HERE="$(${coreutils}/bin/dirname "$WRAPPER")"'
    patchShebangs "$out/libexec/helium/helium-wrapper"

    for executable in helium helium_crashpad_handler chromedriver; do
      patchelf \
        --set-interpreter "$(cat "$NIX_CC/nix-support/dynamic-linker")" \
        --set-rpath "${libraryPath}" \
        "$out/libexec/helium/$executable"
    done

    for library in libEGL.so libGLESv2.so libqt5_shim.so libqt6_shim.so libvk_swiftshader.so; do
      patchelf --set-rpath "${libraryPath}" "$out/libexec/helium/$library"
    done

    rm "$out/libexec/helium/libvulkan.so.1"
    ln -s "${lib.getLib vulkan-loader}/lib/libvulkan.so.1" \
      "$out/libexec/helium/libvulkan.so.1"


    install -m 0644 "$out/libexec/helium/helium.desktop" \
      "$out/share/applications/helium.desktop"
    substituteInPlace "$out/share/applications/helium.desktop" \
      --replace-fail 'Exec=helium' "Exec=$out/bin/helium"
    ln -s "$out/libexec/helium/product_logo_256.png" \
      "$out/share/icons/hicolor/256x256/apps/helium.png"

    makeWrapper "$out/libexec/helium/helium-wrapper" "$out/bin/helium" \
      --prefix LD_LIBRARY_PATH : "${libraryPath}" \
      --prefix PATH : "${
        lib.makeBinPath [
          coreutils
          xdg-utils
        ]
      }" \
      --set CHROME_WRAPPER helium \
      --prefix XDG_DATA_DIRS : "$out/share:${adwaita-icon-theme}/share:${gsettings-desktop-schemas}/share/gsettings-schemas/${gsettings-desktop-schemas.name}:${gtk3}/share/gsettings-schemas/${gtk3.name}:${gtk4}/share/gsettings-schemas/${gtk4.name}:${addDriverRunpath.driverLink}/share" \
      ''${qtWrapperArgs[@]}

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    "$out/bin/helium" --version | grep -F "${release.version}"
    runHook postInstallCheck
  '';

  meta = {
    description = "Privacy-focused Chromium-based web browser";
    homepage = "https://helium.computer";
    changelog = "https://github.com/imputnet/helium-linux/releases/tag/${release.version}";
    license = with lib.licenses; [
      gpl3Only
      bsd3
    ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "helium";
  };
}
