# MiSans 字体（小米官方，Nixpkgs 未收录，从官方 zip 安装 ttf）
{ lib, stdenvNoCC, fetchurl, unzip }:

stdenvNoCC.mkDerivation {
  pname = "misans";
  version = "4.009";

  src = fetchurl {
    url = "https://hyperos.mi.com/font-download/MiSans.zip";
    # 官方下载链接无版本号，hash 固定内容；官方更新后需重新取哈希
    hash = "sha256-tqofyCcDWSJhLfjt825WCbyhxUQeJc1XVyIEVpt7gdk=";
  };

  nativeBuildInputs = [ unzip ];

  unpackPhase = ''
    runHook preUnpack
    unzip -j $src 'MiSans/ttf/*.ttf'
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/fonts/truetype
    cp *.ttf $out/share/fonts/truetype/
    runHook postInstall
  '';

  meta = {
    description = "MiSans 简体中文字体";
    homepage = "https://hyperos.mi.com/font";
    # MiSans 字体知识产权许可协议：免费商用
    license = lib.licenses.free;
    platforms = lib.platforms.all;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
