{
  description = "My NixOS Flake Configuration";

  inputs = {
    nixpkgs.url = "git+https://mirrors.nju.edu.cn/git/nixpkgs.git?ref=nixos-unstable&shallow=1";
    #home-manager = {
    #  url = "github:nix-community/home-manager";
    #  inputs.nixpkgs.follows = "nixpkgs";
    #};
  };

  outputs = { self, nixpkgs, home-manager }: {
    nixosConfigurations.kitra-laptop-nix = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hardware-configuration.nix
        ./configuration.nix
        home-manager.nixosModules.home-manager # 导入 Home Manager 模块
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          # 将用户配置指向 home.nix 文件
          home-manager.users.kitra = import ./home.nix;
        }
      ];
    };
  };
}
