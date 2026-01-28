{ config, pkgs, lib, inputs, pkgs-unstable, username, hostname, ... }:
# ^
# | These are the arguments passed to this module:
# | - config: The full system configuration
# | - pkgs: The nixpkgs package set (from flake.nix)
# | - lib: NixOS library functions
# | - inputs: All flake inputs (from specialArgs in flake.nix)
# | - pkgs-unstable: Unstable package set (from specialArgs)
# | - username: Your username (from specialArgs)
# | - hostname: Your hostname (from specialArgs)

{
  # Here should be specified all additional modules that are shared among all systems
  # imports = [ ];

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];

    # Optimize storage with auto-optimization
    auto-optimise-store = true;
  };

  # Flakes make it easy to have many generations
  # Auto-cleanup prevents disk from filling up
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # Boot loader
  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 10;
    };
    efi.canTouchEfiVariables = true;
  };

  # Delete after disko/hardware configuration
  # Kernel parameters for LUKS
  # boot.initrd.luks.devices = {
  #   cryptroot = {
  #     device = "/dev/disk/by-uuid/XXXX";  # Will be auto-filled by hardware-configuration.nix
  #     bypassWorkqueues = true;
  #   };
  # };

  # Allows to mount any removable disks with supported filesystems.
  boot.supportedFilesystems = [ "btrfs" "ext4" "vfat" "ntfs" ];

  # Zram swap. Memory usage is defined per host specifically.
  zramSwap.enable = true;

  # Small emergency swap. System will use zram by default (it has priority 5),
  # and only when it's full it will fall back to swap file (priority -1)
  swapDevices = [
    {
      device = "/swapfile";
      size = 4096;
      priority = -1;
    }
  ];

  networking = {
    hostName = hostname;
    networkmanager.enable = true;

    firewall = {
      enable = true;
      # Allow SSH incoming requests
      allowedTCPPorts = [ 22 ];
      # allowedUDPPorts = [ ];
    };

    # Better WiFi performance
    networkmanager.wifi.powersave = false;
  };

  time.timeZone = "Europe/Moscow";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocales = [ "ru_ru.UTF-8" ];

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # Conflicts with PipeWire
  hardware.pulseaudio.enable = false;
  # RealtimeKit system service, which hands out realtime scheduling priority to user processes on demand.
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Backlight non-root control
  programs.light.enable = true;

  # Power management daemon
  services.power-profiles-daemon.enable = true;

  # DBus interface for apps for power management
  services.upower.enable = true;

  # See if hardware-configuration.nix enables it
  # powerManagement = {
  #   enable = true;
  #   cpuFreqGovernor = "powersave";
  # };

  # Links `/libexec` from derivations to `/run/current-system/sw`
  # `/libexec` contains helper internal executables, that are not meant for direct user execution,
  # but binaries that depend on those helpers can look specifically for symlinks and will fail without them
  environment.pathsToLink = [ "/libexec" ];

  # Despite a name, also maybe needed by wayland compositors
  services.xserver.enable = true;

  programs.sway = {
    enable = true;

    # Execute sway with required environment variables for GTK applications when needed
    wrapperFeatures.gtk = true;

    # XWayland support
    xwayland.enable = true;

    extraPackages = with pkgs; [
      swaylock
      swayidle
      swaybg
      wl-clipboard
      wl-clipboard-x11
      grim
      slurp
      tofi
      waybar
      mako
      wob
      brightnessctl
      # wdisplays
      # kanshi
    ];

    extraSessionCommands = ''
      export XDG_CURRENT_DESKTOP=sway
      export XDG_SESSION_TYPE=wayland
      export QT_QPA_PLATFORM=wayland
      export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
      export SDL_VIDEODRIVER=wayland
    '';
  };

  # Series of D-Bus interfaces for primarily sandboxed apps to interect with a "desktop"
  xdg.portal = {
    enable = true;
    # Wayland specific interfaces
    wlr.enable = true;
    # GTK specific interfaces
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    # Makes all `xdg-open` calls go through portals, even for non sandboxed apps
    # Consider using it ONLY when running a lot of binaries through FHS envs.
    # xdgOpenUsePortal = true;
  };

  # Using username variable from flake.nix
  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
    ];
  };

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    # Basic utilities
    vim
    git
    wget
    curl
    # vivaldi

    btop
    iotop # io monitoring
    iftop # network monitoring
    pciutils # lspci
    usbutils # lsusb

    # Graphics info tools
    glxinfo
    vulkan-tools
    nvtop

    # EXAMPLE: Using unstable packages for specific tools
    # pkgs-unstable.neovim  # Get latest neovim from unstable
  ];

  # TODO: In user settings set to `helix`
  environment.variables.EDITOR = "vim";

  # Add specific shells to /etc/shells to be able to log with them
  environment.shells = with pkgs; [
    bash
    zsh
  ];

  # Set default shell for all users
  users.defaultUserShell = pkgs.zsh;

  fonts = {
    # Create a directory with links to all fonts in /run/current-system/sw/share/X11/fonts
    fontDir.enable = true;

    # Use specified fonts in `defaultFonts` below
    enableDefaultFonts = false;

    packages = [
      inputs.aporetic-nerd-font.packages.${pkgs.system}.default
    ] ++ (with pkgs: [
      (nerdfonts.override {
        fonts = [
          "JetBrainsMono"
          "FiraCode"
          "Iosevka"
        ];
      })
      noto-fonts
      noto-fonts-emoji
      font-awesome
    ]);

    # User defined default fonts
    fontconfig.defaultFonts = {
      serif = [ "AporeticSerifMonoNerdFont-Regular" ];
      sansSerif = [ "AporeticSansMonoNerdFont-Regular" ];
      monospace = [ "AporeticSerifMonoNerdFont-Regular" ];
      emoji = [ "AporeticSerifMonoNerdFont-Regular" ];
    };
  };

  security.polkit.enable = true;

  # TODO: Security: Consider using keyring

  # OpenSSH daemon
  services.openssh = {
    enable = true;
    settings = {
      # Allow to run gui apps on a remote machine, using host's x server
      X11Forwarding = true;
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  # Convinient manager for firmware updates
  # https://nixos.wiki/wiki/Fwupd
  services.fwupd.enable = true;

  # Daemon for keyboard remaps
  services.keyd = {
    enable = true;
    keyboards = {
      default = {
        ids = [ "*" ];
        settings = {
          main = {
            # capslock on hold - ctrl, on tap - esc
            capslock = "overload(control, esc)";
          };
        };
      };
    };
  };

  # https://flatpak.org/setup/NixOS
  services.flatpak.enable = true;

  # DON'T CHANGE after initial installation
  # This ensures system compatibility across upgrades
  system.stateVersion = "24.11";
}

# USING UNSTABLE PACKAGES
# =======================
# You can selectively use packages from nixpkgs-unstable:
#
# Option 1: In systemPackages
#   environment.systemPackages = with pkgs; [
#     firefox              # From stable (24.11)
#     pkgs-unstable.neovim # From unstable (latest)
#   ];
#
# Option 2: Create an overlay (advanced)
#   nixpkgs.overlays = [
#     (final: prev: {
#       neovim = pkgs-unstable.neovim;
#     })
#   ];
#
# Option 3: In Home Manager (home.nix)
#   home.packages = [
#     pkgs.firefox
#     pkgs-unstable.vscode
#   ];

# MODULAR CONFIGURATION
# =====================
# As your config grows, you can split it into modules:
#
# /etc/nixos/
# ├── flake.nix
# ├── configuration.nix        # Main config (this file)
# ├── hardware-configuration.nix
# └── modules/
#     ├── nvidia.nix           # NVIDIA-specific config
#     ├── gaming.nix           # Gaming setup
#     └── development.nix      # Dev tools
#
# Then import in flake.nix:
#   modules = [
#     ./configuration.nix
#     ./modules/nvidia.nix
#     ./modules/gaming.nix
#   ];
#
# Or import in configuration.nix:
#   imports = [
#     ./modules/nvidia.nix
#     ./modules/gaming.nix
#   ];
