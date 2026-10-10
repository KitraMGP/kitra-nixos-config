# Windows 简体中文原版字体（中易宋体/黑体/楷体/仿宋 + 微软雅黑）
# Nixpkgs 不收录：中易、微软字体许可不允许再分发，故标记 unfree 自行打包
{ lib, stdenvNoCC, fetchzip }:

stdenvNoCC.mkDerivation {
  pname = "windows-zh-fonts";
  version = "1.0";

  # 取 wine 分支：该仓库 main 分支的中文字体内容已被清零，wine 分支才是完整字体
  src = fetchzip {
    url = "https://github.com/zanjie1999/windows-fonts/archive/2c549d57df32d8bdface2df39f4572a987ce1bd1.tar.gz";
    hash = "sha256-OEHZhABlURNK3ttuFGR4I2sVj1sE4LIyI6GjaYFlCrY=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/fonts/truetype
    cp simsun.ttc simsunb.ttf simhei.ttf simkai.ttf simfang.ttf \
       msyh.ttc msyhl.ttc \
       $out/share/fonts/truetype/

    runHook postInstall
  '';

  meta = {
    description = "Windows 简体中文原版字体（SimSun/NSimSun/SimSun-ExtB/SimHei/KaiTi/FangSong/Microsoft YaHei）";
    homepage = "https://github.com/zanjie1999/windows-fonts";
    license = lib.licenses.unfree;
    platforms = lib.platforms.all;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
