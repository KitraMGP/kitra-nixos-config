{ config, lib, pkgs, ... }:

{
  home.username = "kitra";
  home.homeDirectory = "/home/kitra";

  home.stateVersion = "26.05";

  # zsh + oh-my-zsh（fishy 主题）；zsh 本体在 configuration.nix 全局安装，这里只管用户配置
  programs.zsh = {
    enable = true;
    package = null;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    oh-my-zsh = {
      enable = true;
      theme = "fishy";
      plugins = [
        "git" # 常用 git 别名
        "sudo" # 双击 Esc 给上一条命令补 sudo
        "colored-man-pages"
      ];
    };
  };

  # package = null 后 HM 不再附带 nix 命令补全，单独保留
  home.packages = [ pkgs.nix-zsh-completions ];

  # fcitx rime ice config
  xdg.dataFile."fcitx5/rime/default.custom.yaml".text = ''
    patch:
      __include: rime_ice_suggestion:/
  '';

  # 开机进入桌面自动开启数字锁定：KWin 会话启动时读取 kcminputrc 的
  # [Keyboard] NumLock（0=开启，1=关闭，2=保持不变）
  # 用 kwriteconfig6 合并写入而非声明整个文件：kcminputrc 里还有 KDE 自己管理的
  # 触控板等设置（[Libinput]），整文件交给 home-manager 会变成只读符号链接，
  # 导致 KDE 无法再保存这些设置。
  home.activation.numLockOn = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file kcminputrc --group Keyboard --key NumLock 0
  '';
}
