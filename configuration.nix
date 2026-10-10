# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nix.settings.substituters = [
    "https://mirrors.nju.edu.cn/nix-channels/store"
    "https://mirrors.ustc.edu.cn/nix-channels/store"
    # "https://cache.nixos.org/" # 保留官方源作为备选
  ];

  boot.loader.systemd-boot.enable = false;
  
  # Use GRUB
  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
    useOSProber = true;
    fontSize = 32;
  };

  boot.loader.efi.canTouchEfiVariables = true;

  # 使用 CachyOS 内核（由 flake 输入 chaotic 提供）
  boot.kernelPackages = pkgs.linuxPackages_cachyos;

  # —— 内存与交换 ——
  # 磁盘交换文件（ext4 根分区），在 zram 用尽后兜底
  swapDevices = [
    { device = "/swapfile"; size = 24 * 1024; priority = 10; } # size 单位 MiB
  ];

  # zram 压缩内存交换（zstd），优先于磁盘 swap 使用
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
    priority = 100;
  };

  # 已用 zram 时关闭 zswap，避免交换页被二次压缩
  boot.kernelParams = [ "zswap.enabled=0" ];

  boot.kernel.sysctl = {
    # zram 命中代价低，积极换出匿名页以保住文件缓存
    "vm.swappiness" = 100;
    # zram/SSD 上交换预读无收益
    "vm.page-cluster" = 0;
    # 保留目录项/索引节点缓存
    "vm.vfs_cache_pressure" = 50;
  };

  # 内存接近耗尽时提前终止最大进程，避免整机卡死
  services.earlyoom = {
    enable = true;
    freeMemThreshold = 10;   # 剩余内存低于 10% 时介入
    freeSwapThreshold = 10;
  };

  networking.hostName = "kitra-laptop-nix"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  networking.proxy.default = "http://127.0.0.1:7897/";
  networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain,*.edu.cn,*.bing.com,*.cn";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Asia/Shanghai";

  # Select internationalisation properties.
  i18n.defaultLocale = "zh_CN.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "zh_CN.UTF-8";
    LC_IDENTIFICATION = "zh_CN.UTF-8";
    LC_MEASUREMENT = "zh_CN.UTF-8";
    LC_MONETARY = "zh_CN.UTF-8";
    LC_NAME = "zh_CN.UTF-8";
    LC_NUMERIC = "zh_CN.UTF-8";
    LC_PAPER = "zh_CN.UTF-8";
    LC_TELEPHONE = "zh_CN.UTF-8";
    LC_TIME = "zh_CN.UTF-8";
  };

  i18n.inputMethod = {
    type = "fcitx5";
    enable = true;
    fcitx5.addons = with pkgs; [
      # 核心：将 rime-ice 作为数据包注入到 fcitx5-rime
      (fcitx5-rime.override { rimeDataPkgs = [ rime-ice ]; })
      
      fcitx5-lua

      # Fcitx5 配置工具，用于图形化管理输入法
      qt6Packages.fcitx5-configtool
      
      # 可选：确保 Fcitx5 与 GTK/Qt 应用良好集成
      fcitx5-gtk
      kdePackages.fcitx5-qt
    ];
  };

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # 排除 Plasma 6 自带的不需要的应用程序
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    elisa
  ];

  # 整套 KDE PIM（KMail、Kontact、Merkuro、Akonadi）由 PIM 模块提供，而非 Plasma 模块
  programs.kde-pim.enable = false;

  # NVIDIA 专有驱动（用户态闭源 + 开源内核模块），安装后自动屏蔽 nouveau
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    # 用 chaotic-nyx 配套的驱动（与 CachyOS 内核匹配且有二进制缓存）。
    # nixpkgs 自带的驱动在该内核上本地编译会因缺少模块签名密钥而失败。
    package = pkgs.nvidia_cachyos;
    open = true;                        # 使用 NVIDIA 开源内核模块
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = true; # 空闲时给独显断电省电
    prime = {
      offload.enable = true;            # 核显渲染，按需调用独显
      offload.enableOffloadCmd = true;  # 生成 nvidia-offload 命令
      amdgpuBusId = "PCI:102:0:0";      # 核显 0000:66:00.0，注意为十进制
      nvidiaBusId = "PCI:1:0:0";        # 独显 0000:01:00.0
    };
  };

  # ASUS 笔记本守护进程：模块会安装 asusctl/supergfxctl 并注册、启动对应服务
  services.asusd.enable = true;
  services.supergfxd.enable = true;
  # asusd 上游 unit 无 [Install] 段，模块也未声明 wantedBy，需显式随 multi-user.target 启动
  systemd.services.asusd.wantedBy = [ "multi-user.target" ];

  # ROG Control Center 图形界面（内置 asusctl 包中）
  programs.rog-control-center.enable = true;

  # Podman 容器（https://wiki.nixos.org/wiki/Podman）
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;                        # 提供 docker -> podman 命令
    defaultNetwork.settings.dns_enabled = true; # podman-compose 容器间可用服务名互访
  };
  # 未限定镜像名（如 nginx）默认从 docker.io 拉取
  virtualisation.containers.registries.settings.unqualified-search-registries = [ "docker.io" ];

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    # jack.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.libinput.enable = true;

  # zsh 作为登录 shell（同时注册进 /etc/shells）
  programs.zsh.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."kitra" = {
    isNormalUser = true;
    description = "Kitra";
    shell = pkgs.zsh;
    extraGroups = [ "networkmanager" "wheel" "podman" ];
    packages = with pkgs; [
      kdePackages.kate
    #  thunderbird
    ];
  };

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # 字体：MiSans 为默认字体，Sarasa Term SC Nerd 为默认等宽字体
  # 两者 Nixpkgs 未收录，均为自定义 derivation（fetchurl 固定 hash，可复现）
  fonts = {
    packages = with pkgs; [
      (callPackage ./misans.nix { })
      (callPackage ./sarasa-term-sc-nerd.nix { })
      noto-fonts # 拉丁字母后备
      noto-fonts-cjk-sans # 汉字缺字时后备
      noto-fonts-color-emoji # emoji
    ];

    # 清晰显示：抗锯齿 + slight hinting + RGB 亚像素渲染
    fontconfig = {
      enable = true;
      antialias = true;
      hinting.enable = true;
      hinting.style = "slight";
      subpixel.rgba = "rgb";
      subpixel.lcdfilter = "default";

      # mkForce：Plasma6 模块会注入 Hack/Noto Sans Mono 等默认值并与本列表合并，
      # 导致 Sarasa 平局后排序垫底
      defaultFonts = {
        sansSerif = pkgs.lib.mkForce [ "MiSans" "Noto Sans CJK SC" "Noto Sans" ];
        serif = pkgs.lib.mkForce [ "MiSans" "Noto Serif" ];
        monospace = pkgs.lib.mkForce [ "Sarasa Term SC Nerd" ];
        emoji = pkgs.lib.mkForce [ "Noto Color Emoji" ];
      };

      localConf = ''
        <?xml version="1.0"?>
        <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
        <fontconfig>
          <!-- 统一简体中文字形：zh 请求按 zh-CN 匹配（避免日文/繁体字形） -->
          <match target="pattern">
            <test name="lang" compare="contains">
              <string>zh</string>
            </test>
            <edit name="lang" mode="assign">
              <string>zh-CN</string>
            </edit>
          </match>

          <!-- Plasma/应用硬编码请求 Noto Sans 时也改用 MiSans，缺字自动回落 -->
          <match target="pattern">
            <test name="family">
              <string>Noto Sans</string>
            </test>
            <edit name="family" mode="prepend" binding="strong">
              <string>MiSans</string>
            </edit>
          </match>
        </fontconfig>
      '';
    };
  };

  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    git
    clash-verge-rev
    gh
    efibootmgr
    python3
    fastfetch
    htop
    btop
    podman-compose
    # C/C++ 工具链：gcc 含 g++，另配 binutils(as/ld/ar 等)、gdb、make、cmake
    gcc
    binutils
    gdb
    gnumake
    cmake
    # Rust：用 nixpkgs 的 rustc/cargo（rustup 的预编译工具链在无 nix-ld 时无法运行）
    rustc
    cargo
    # Node.js 与 pnpm
    nodejs
    pnpm
    vscode
    vlc
    qq
    wechat
  ];

  environment.sessionVariables = {
    HTTP_PROXY = "http://127.0.0.1:7897/";
    HTTPS_PROXY = "http://127.0.0.1:7897";
    # http_proxy = "http://127.0.0.1:7897/";
    # https_proxy = "http://127.0.0.1:7897";

    NO_PROXY = "127.0.0.1,localhost,internal.domain,*.edu.cn,*.bing.com,*.cn";
    # no_proxy = "127.0.0.1,localhost,internal.domain,*.edu.cn,*.bing.com,*.cn";
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "26.05"; # Did you read the comment?

}
