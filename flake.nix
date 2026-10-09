{
  description = "My NixOS Flake Configuration";

  inputs = {
    nixpkgs.url = "git+https://mirrors.nju.edu.cn/git/nixpkgs.git?ref=nixos-unstable&shallow=1";
    # CachyOS 内核（chaotic-nyx），提供 pkgs.linuxPackages_cachyos
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, chaotic }: {
    nixosConfigurations.kitra-laptop-nix = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        chaotic.nixosModules.default # 导入 chaotic-nyx 模块，提供 CachyOS 内核
        ./hardware-configuration.nix
        ./configuration.nix
        home-manager.nixosModules.home-manager # 导入 Home Manager 模块
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          # 冲突的既有文件自动改名为 .bak，避免激活失败
          home-manager.backupFileExtension = "bak";
          # 将用户配置指向 home.nix 文件
          home-manager.users.kitra = import ./home.nix;
        }
      ];
    };
  };
}
