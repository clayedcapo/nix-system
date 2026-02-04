# =============================================================================
# SHARED SYSTEM CONFIGURATION
# =============================================================================
# This file contains configuration shared between all hosts
# Host-specific shared settings are in ./hosts/<hostname>/
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
  # NOTE: Here should be specified all additional modules that are shared among all hosts
  # imports = [ ];
  #
  # ===========================================================================
  # NIX SETTINGS
  # ===========================================================================
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];

    # Automatically detect files in the store that have identical contents, and replaces them with hard links to a single copy
    auto-optimise-store = true;
  };

  # Flakes make it easy to have many generations
  # Auto-cleanup prevents disk from filling up
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # Allow non-free packages
  nixpkgs.config.allowUnfree = true;

  # Remove channel related tools and configs
  nix.channel.enable = false;

  # ===========================================================================
  # BOOT
  # ===========================================================================
  boot.loader = {
    systemd-boot = {
      enable = true;
      # i.e. generations limit
      configurationLimit = 10;
    };
    # Whether the installation process is allowed to modify EFI boot variables
    efi.canTouchEfiVariables = true;
  };

  # Allows to mount any removable disks with supported filesystems.
  boot.supportedFilesystems = [ "btrfs" "ext4" "vfat" "ntfs" ];

  # ===========================================================================
  # MEMORY & SWAP
  # ===========================================================================
  # Memory hierarchy with zram-based swap and emergency disk swap
  #
  # ┌─────────────────────────────────────────────────────────────────────────┐
  # │                      MEMORY USAGE HIERARCHY                             │
  # └─────────────────────────────────────────────────────────────────────────┘
  #
  # ┌──────────────────────┐
  # │   Physical RAM       │  ← Primary memory (fastest)
  # │   (Host-specific)    │
  # └──────────┬───────────┘
  #            │ Paging out
  #            ↓
  # ┌──────────────────────┐
  # │   Zram Swap          │  ← Compressed RAM (fast, priority: 5)
  # │   (Configured below) │     Acts as "extra RAM" with compression
  # └──────────┬───────────┘     Size: percentage of physical RAM
  #            │ Only when zram is full
  #            ↓
  # ┌──────────────────────┐
  # │   Disk Swap File     │  ← Emergency overflow (slow, priority: -1)
  # │   /swapfile (4GB)    │     Rarely used, prevents OOM crashes
  # └──────────────────────┘
  #
  # HOST-SPECIFIC CONFIGURATIONS:
  # ┌────────────────────────────────────────────────────────────────────────┐
  # │ Host: main (high RAM system)                                           │
  # │   • zramSwap.memoryPercent = 40                                        │
  # │     Example: 16GB RAM → 6.4GB zram (compressed to ~3GB actual usage)   │
  # │   • vm.swappiness = 150 (aggressive swapping to fast zram)             │
  # │   • /tmp on zram (14% of RAM) for fast temporary storage               │
  # ├────────────────────────────────────────────────────────────────────────┤
  # │ Host: secondary (low RAM system)                                       │
  # │   • zramSwap.memoryPercent = 20                                        │
  # │     Example: 8GB RAM → 1.6GB zram (compressed to ~800MB actual usage)  │
  # │   • vm.swappiness = 100 (moderate swapping, conserves limited RAM)     │
  # │   • No /tmp on zram (preserves RAM for applications)                   │
  # └────────────────────────────────────────────────────────────────────────┘
  #
  # SWAP PRIORITY SYSTEM:
  #   Higher priority = used first
  #   • Zram: priority 5 (default) → Used when RAM is under high pressure
  #   • Disk: priority -1 → Only used when zram is exhausted
  #
  # TUNING PARAMETERS (in hosts/*/default.nix):
  #   • vm.swappiness: How aggressively to use swap (0-200)
  #   • vm.page-cluster: Swap readahead (0 for zram = optimal)
  #   • vm.vfs_cache_pressure: Cache vs swap preference
  #   • vm.watermark_boost_factor and vm.watermark_scale_factor: Memory reclaim aggressiveness
  #
  # ===========================================================================

  # Enable zram swap (size configured per-host in hosts/*/default.nix)
  zramSwap.enable = true;

  # Emergency disk-based swap (only used when zram is full)
  swapDevices = [
    {
      device = "/swapfile";
      size = 4096;       # 4GB - enough for emergency situations
      priority = -1;     # Lower than zram (5), used as last resort
    }
  ];

  # ===========================================================================
  # NETWORKING
  # ===========================================================================
  networking = {
    hostName = hostname;
    networkmanager.enable = true;

    firewall = {
      enable = true;
      # Allow SSH and HTTPS incoming requests
      allowedTCPPorts = [ 22 443 ];
      # allowedUDPPorts = [ ];
    };

    # Better WiFi performance
    networkmanager.wifi.powersave = false;
  };

  # ===========================================================================
  # LOCALIZATION
  # ===========================================================================
  time.timeZone = "Europe/Moscow";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocales = [ "ru_RU.UTF-8/UTF-8" ];

  # ===========================================================================
  # HARDWARE
  # ===========================================================================
  # NOTE: Hardware options are machine specific primarily. See in `./hosts`
  #
  # -------------------------------------------------------------------------
  # Bluetooth
  # -------------------------------------------------------------------------
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # -------------------------------------------------------------------------
  # Audio (PipeWire)
  # -------------------------------------------------------------------------
  # Conflicts with PipeWire
  hardware.pulseaudio.enable = false;

  # RealtimeKit system service, which hands out realtime scheduling priority to user processes on demand
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
  };

  # ===========================================================================
  # POWER MANAGEMENT
  # ===========================================================================
  # Backlight non-root control
  programs.light.enable = true;

  # Power management daemon
  services.power-profiles-daemon.enable = true;

  # DBus interface for apps for power management
  services.upower.enable = true;

  # TODO: See if hardware-configuration.nix enables it
  # powerManagement = {
  #   enable = true;
  #   cpuFreqGovernor = "powersave";
  # };
  #
  # ===========================================================================
  # DESKTOP ENVIRONMENT (Sway/Wayland)
  # ===========================================================================
  # Links paths from derivations to `/run/current-system/sw`
  # - `/libexec`: Helper internal executables needed by some binaries
  # - `/share/zsh`: Needed for zsh completions of system packages
  environment.pathsToLink = [ "/libexec" "/share/zsh" ];

  # TODO: Despite a name, also maybe needed by wayland compositors, enable after testing if needed
  # services.xserver.enable = true;

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
      wl-color-picker
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

    # Wayland specific env vars:
    #   - NIXOS_OZONE_WL=1: Enable Wayland support for Ozone-based applications (Chrome, Electron apps)
    #   - ELECTRON_OZONE_PLATFORM_HINT=auto: Tells Electron apps (VS Code, Discord, etc.) to automatically use Wayland
    #   - XDG_CURRENT_DESKTOP=sway: Identifies your desktop environment as Sway
    #   - XDG_SESSION_TYPE=wayland: Tells applications your session type is Wayland
    #   - QT_QPA_PLATFORM=wayland: Tells Qt-based applications (KDE apps, many others) to use Wayland
    #   - QT_WAYLAND_DISABLE_WINDOWDECORATION=1: Disables Qt's own window decorations on Wayland and lets Sway handle them
    #   - SDL_VIDEODRIVER=wayland: Tells SDL (Simple DirectMedia Layer, used in games and multimedia apps) to use Wayland for video output
    #   - GDK_BACKEND=wayland: Tells GTK applications (GNOME apps, Firefox, etc.) to use Wayland instead of X11
    extraSessionCommands = ''
      export NIXOS_OZONE_WL=1
      export ELECTRON_OZONE_PLATFORM_HINT=auto
      export XDG_CURRENT_DESKTOP=sway
      export XDG_SESSION_TYPE=wayland
      export QT_QPA_PLATFORM=wayland
      export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
      export SDL_VIDEODRIVER=wayland
      export GDK_BACKEND=wayland
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
    # Consider using it ONLY when running a lot of binaries through FHS envs
    # xdgOpenUsePortal = true;

    config.common.default = [ "gtk" ];
  };

  xdg = {
    mime.enable = true;    # file associations - essential
    icons.enable = true;   # icon themes - needed for GUI apps

    # Skip these for Sway:
    # autostart.enable = true;  # Sway uses exec mechanism
    # menus.enable = true;      # not used by tofi/wofi
  };


  # ===========================================================================
  # USERS
  # ===========================================================================
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

  # Set default shell for all users
  users.defaultUserShell = pkgs.zsh;

  # Enable zsh system-wide (required when setting it as user shell)
  programs.zsh = {
    enable = true;

    enableCompletion = true;           # Enable tab completion
    autosuggestions.enable = true;      # Fish-like autosuggestions from history
    syntaxHighlighting.enable = true;  # Syntax highlighting for commands
  };

  # ===========================================================================
  # PACKAGES
  # ===========================================================================
  environment.systemPackages = with pkgs; [
    # Basic utilities
    zsh
    bash
    helix
    git
    gnumake # make build system
    just # command runner, substitutes make, simpler
    fastfetch
    yazi

    # System tools
    pciutils # lspci
    usbutils # lsusb
    psmisc # tools that use /proc filesystem: `fuser`, `killall`, `peekfd`, `prtstat`, `pslog`, `pstree`
    ethtool
    hdparm # for ATA/SATA maintainence
    gptfdisk # `cgdisk`, `fixparts`, `gdisk`, `sgdisk`

    # Monitoring
    btop
    strace # syscall tracer
    ltrace # dynamic libcall tracer
    iotop-c # io monitoring
    iftop # network monitoring
    procs # modern ps
    lsof # tool to list open files
    systat # provides `cifsiostat`, `iostat`, `mpstat`, `pidstat`, `sadf`, `sar`, `tapestat`
    sysbench # scriptable multi-threaded benchmark tool based on LuaJIT
    systemctl-tui

    # Text Processing
    gnugrep # GNU grep, provides `grep`, `egrep`, `fgrep` commands
    gawk # GNU awk, a pattern scanning and processing language
    gnutar # GNU implementation of the `tar` archiver
    gnused # GNU sed, very powerful (mainly for replacing text in files)
    findutils # `find`, `locate`, `updatedb`, `xargs`
    jq
    yq-go # YAML processor
    jc # serializer of popular cmd tools' outputs to JSON
    duf # disk usage/free utility - a better 'df' alternative
    sad # sed replacement, with diffs
    fzf
    fd
    ripgrep
    ast-grep # syntax-aware grep/sed, write code patterns to locate and modify code, based on AST
    bat
    eza
    zoxide
    dust # du replacement
    tokei # count lines of code

    # Archives
    zip
    xz
    zstd
    unzipNLS # provides `funzip`, `unzip`, `unzipsfx`, `zipgrep`, `zipinfo` commands
    p7zip

    # Networking
    wget
    curl
    dnsutils
    mtr # `ping` and `traceroute` in one util
    gping # `ping` with graph
    doggo # DNS-client, replacement for `dig`
    # httpie
    # curlie # curl with httpie
    aria2 # versatile multi-protocol downloader (https://aria2.github.io)
    socat # `netcat` replacement
    iperf # tool to measure IP bandwidth using UDP or TCP
    tcpdump # network sniffer

    # Libraries
    poppler # PDF rendering library
    resvg # SVG rendering library

    # eBPF tools (https://ebpf.io/what-is-ebpf/)
    bpftrace
    bpftop
    bpfmon

    # Benchmarking
    hyperfine

    # Graphics info tools
    vulkan-tools
    libva-utils # collection of utilities and examples to exercise VA-API
    mesa-demos # collection of demos and test programs for OpenGL and Mesa

    # File transfer
    rsync
    croc # file transfer between computers securely and easily

    # Security
    argon2 # password-hashing function
    openssl
    gnupg

    # Firmware
    linux-firmware

    # Miscellaneous
    file # show file type
    which
    tree
    tealdeer # fast tldr version

    # EXAMPLE: Using unstable packages for specific tools
    # pkgs-unstable.neovim  # Get latest neovim from unstable
  ];

  # BCC - Tools for BPF-based Linux IO analysis, networking, monitoring, and more
  # https://github.com/iovisor/bcc
  programs.bcc.enable = true;

  # ===========================================================================
  # ENVIRONMENT
  # ===========================================================================
  environment.variables= {
    EDITOR = "helix";
    VISUAL = "helix";
  };

  # Add specific shells to /etc/shells to be able to log with them
  environment.shells = with pkgs; [
    bash
    zsh
  ];

  # Will make many terminal types available system-wide in terminfo database
  # NOTE: Probably not needed, but in case of using new modern terminal can help with different errors related to
  # inability to query terminfo on those terminals by programs like helix, tmux and etc.
  environment.enableAllTerminfo = true;

  # ===========================================================================
  # DOCUMENTATION
  # ===========================================================================
  documentation = {
    enable = true;
    man.enable = true;          # Man pages for system packages
    man.generateCaches = true;  # Faster apropos/whatis lookups
    nixos.enable = true;        # NixOS manual (configuration.nix options reference)
    dev.enable = false;         # Development documentation
    # doc.enable = true;        # HTML docs from packages (uses disk space)
  };

  # ===========================================================================
  # FONTS
  # ===========================================================================
  fonts = {
    # Create a directory with links to all fonts in /run/current-system/sw/share/X11/fonts
    fontDir.enable = true;

    # Use specified fonts in `defaultFonts` below
    enableDefaultPackages = false;

    packages = [
      inputs.aporetic-nerd-font.packages.${pkgs.system}.default
    ] ++ (with pkgs; [
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
      serif = [ "AporeticSerifMonoNerdFont" "Noto Serif" ];
      sansSerif = [ "AporeticSansMonoNerdFont" "Noto Sans" ];
      monospace = [ "AporeticSerifMonoNerdFont" "JetBrainsMono Nerd Font" ];
      emoji = [ "Noto Color Emoji" ];
    };
  };

  # ===========================================================================
  # SECURITY
  # ===========================================================================
  security.polkit.enable = true;

  # Daemon to ban hosts that cause multiple authentication errors with logs lookup
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    bantime = "1h";
  };

  # TODO: Security: Consider using keyring
  #
  # ===========================================================================
  # SERVICES
  # ===========================================================================
  #
  # -------------------------------------------------------------------------
  # OpenSSH
  # -------------------------------------------------------------------------
  services.openssh = {
    enable = true;
    settings = {
      # Allow to run gui apps on a remote machine, using host's x server
      X11Forwarding = true;
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  # -------------------------------------------------------------------------
  # Firmware Updates
  # -------------------------------------------------------------------------
  # Convenient manager for firmware updates
  # https://nixos.wiki/wiki/Fwupd
  services.fwupd.enable = true;

  # -------------------------------------------------------------------------
  # Keyboard Remapping
  # -------------------------------------------------------------------------
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

  # -------------------------------------------------------------------------
  # Flatpak
  # -------------------------------------------------------------------------
  # https://flatpak.org/setup/NixOS
  services.flatpak.enable = true;

  # ===========================================================================
  # STATE VERSION
  # ===========================================================================
  # DON'T CHANGE after initial installation
  # This ensures system compatibility across upgrades
  system.stateVersion = "25.11";
}
# =============================================================================
# TIPS & TRICKS
# =============================================================================
#
# USING UNSTABLE PACKAGES
# -----------------------
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

