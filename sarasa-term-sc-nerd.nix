# Sarasa Term SC Nerd 字体（Nixpkgs 未收录，从 GitHub release 的 7z 包安装）
{ lib, stdenvNoCC, fetchurl, _7zz }:

stdenvNoCC.mkDerivation rec {
  pname = "sarasa-term-sc-nerd";
  version = "2.3.1";

  src = fetchurl {
    url = "https://github.com/laishulu/Sarasa-Term-SC-Nerd/releases/download/v${version}/SarasaTermSCNerd.ttf.7z";
    hash = "sha256-REg7dJ7YJhEcFQ43+SIJkncJu1PsUCESlwHMfZftoKk=";
  };

  nativeBuildInputs = [ _7zz ];

  unpackPhase = ''
    runHook preUnpack
    7zz x -y $src
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/fonts/truetype
    cp *.ttf $out/share/fonts/truetype/
    runHook postInstall
  '';

  meta = {
    description = "Sarasa Term SC with Nerd Font glyphs";
    homepage = "https://github.com/laishulu/Sarasa-Term-SC-Nerd";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
