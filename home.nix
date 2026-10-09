{ config, pkgs, ... }:

{
  home.username = "kitra";
  home.homeDirectory = "/home/kitra";

  home.stateVersion = "26.05";

  # fcitx rime ice config
  xdg.dataFile."fcitx5/rime/default.custom.yaml".text = ''
    patch:
      __include: rime_ice_suggestion:/
  '';
}
