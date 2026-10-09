{ config, pkgs, ... }:

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
}
