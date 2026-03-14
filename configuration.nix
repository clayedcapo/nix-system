# =============================================================================
# SHARED SYSTEM CONFIGURATION
# =============================================================================
# This file contains configuration shared between all hosts
# Host-specific shared settings are in ./hosts/<hostname>/
{ config, pkgs, lib, inputs, pkgs-stable, username, hostname, ... }:
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
      # Whether to allow editing the kernel command line at boot
      # WARN: If set to true, then it allows gaining root access by passing init=/bin/sh
      editor = false;
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
  services.pulseaudio.enable = false;

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
  # NOTE: `brightnessctl` provides the same functionality
  # programs.light.enable = true;

  # Power management daemon
  services.power-profiles-daemon.enable = true;

  # DBus interface for apps for power management
  services.upower.enable = true;

  # Enables support for suspend-to-RAM and powersave features on laptops
  powerManagement = {
    enable = true;
    # WARN: Probably conflicts with power-profiles-daemon that sets governer dynamically
    # cpuFreqGovernor = "performance";
  };

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

  # ===========================================================================
  # XDG
  # ===========================================================================
  # Series of D-Bus interfaces for primarily sandboxed apps to interact with a "desktop"
  xdg.portal = {
    enable = true;
    # Wayland specific interfaces
    wlr.enable = true;
    # GTK specific interfaces
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    # Makes all `xdg-open` calls go through portals, even for non sandboxed apps
    # Consider using it ONLY when running a lot of binaries through FHS envs
    # xdgOpenUsePortal = true;

    config.common.default = [ "wlr" "gtk" ];
  };

  xdg = {
    mime.enable = true;    # file associations - essential
    icons.enable = true;   # icon themes - needed for GUI apps

    # Disable those for Sway:
    autostart.enable = lib.mkDefault false;  # Sway uses exec mechanism
    menus.enable = lib.mkDefault false;      # not used by tofi/wofi
  };

  # Enable proposed Default Terminal Execution Specification (https://gitlab.freedesktop.org/xdg/xdg-specs/-/merge_requests/46)
  xdg.terminal-exec = {
    enable = true;
    settings = {
      default = [
        # "Alacritty.desktop"
        "com.mitchellh.ghostty.desktop"
      ];
    };
  };

  # ===========================================================================
  # USERS
  # ===========================================================================
  # TODO: Consider setting passwords declaratively somehow
  # Don't allow mutation of users outside the config
  # users.mutableUsers = false;

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
  # NOTE: Some packages here (fzf, bat, eza, zoxide, fastfetch, tealdeer) are also
  # configured via Home Manager programs.* modules for shell integration.
  # They are kept here to make them available to root. With useGlobalPkgs = true,
  # both reference the same store path — no disk duplication.
  environment.systemPackages = with pkgs; [
    # Basic utilities
    zsh
    bash
    helix
    neovim
    git
    git-lfs
    jujutsu
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
    sysstat # provides `cifsiostat`, `iostat`, `mpstat`, `pidstat`, `sadf`, `sar`, `tapestat`
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
    unrar

    # Networking
    wget
    curl
    dnsutils
    mtr # `ping` and `traceroute` in one util
    gping # `ping` with graph
    doggo # DNS-client, replacement for `dig`
    nmap # `nmap`, `ncat`, `nping`
    # httpie
    # curlie # curl with httpie
    # netplan # declarative network configuration tool
    aria2 # versatile multi-protocol downloader (https://aria2.github.io)
    socat # `netcat` replacement
    iperf # tool to measure IP bandwidth using UDP or TCP
    tcpdump # network sniffer
    throne # proxy client

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
    libargon2 # password-hashing function
    openssl
    gnupg

    # NOTE: Not needed in general (hardware-configuration.nix handles firmware)
    # But in case of missing some special firmware enable it
    # Firmware
    # linux-firmware

    # Miscellaneous
    file # show file type
    which
    tree
    tealdeer # fast tldr version
    man-pages # Linux development manual pages
    man-pages-posix # POSIX man-pages (0p, 1p, 3p)

    # EXAMPLE: Using unstable packages for specific tools
    # pkgs-unstable.neovim  # Get latest neovim from unstable
  ];

  # BCC - Tools for BPF-based Linux IO analysis, networking, monitoring, and more
  # https://github.com/iovisor/bcc
  programs.bcc.enable = true;

  # ===========================================================================
  # ENVIRONMENT
  # ===========================================================================
  environment.variables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
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
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-mono
      nerd-fonts.iosevka
      noto-fonts
      noto-fonts-color-emoji
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
  # CONTAINERIZATION (PODMAN)
  # ===========================================================================
  virtualisation.podman = {
    enable = true;
    # Enable compatibility layer that will alias the docker commands to the podman commands
    dockerCompat = true;
    # Create the podman socket in place of the docker socket for tools that expect docker API
    dockerSocket.enable = true;
    # Enables DNS resolution in containers
    defaultNetwork.settings.dns_enabled = true;
    # TODO: Maybe enable in the future to enhance workflow
    # autoPrune.enable = true;
    # TODO: Same as above. Should be enabled when a need for a programmatic access to a podman CLI arises
    # networkSocket = {};
  };

  # Declaratively manage containers as systemd services that auto-start on boot
  # NOTE: Uncomment and configure if you need long-running containers managed by NixOS
  # virtualisation.oci-containers = {
  #   backend = "podman";
  #   containers.myapp = {
  #     image = "nginx:latest";
  #     ports = [ "80:80" ];
  #     autoStart = true;
  #   };
  # };

  # Configure registries for automatic image name resolution in CLI
  virtualisation.containers.registries.search = [ "docker.io" "quay.io" ];

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
            esc = "capslock";
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

  # -------------------------------------------------------------------------
  # VPN (Throne)
  # -------------------------------------------------------------------------
  programs.throne = {
    enable = true;
    tunMode.enable = true;
  };

  # ===========================================================================
  # NEOVIM (SYSTEM WIDE CONFIGURATION)
  # ===========================================================================
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    configure = {
      packages.myVimPackage.start = [
        (pkgs.vimUtils.buildVimPlugin {
          name = "koda-nvim";
          src = pkgs.fetchFromGitHub {
            owner = "oskarnurm";
            repo = "koda.nvim";
            rev = "main";
            hash = "sha256-8tZWCL+XBFIiBeOOOnXG590irPRmhr23J4WhrPkGEzA";  # run build once to get the error with correct hash
          };
        })

        # Prebuilt binaries
        pkgs.vimPlugins.telescope-nvim
        pkgs.vimPlugins.telescope-fzf-native-nvim
        pkgs.vimPlugins.mini-nvim
        pkgs.vimPlugins.nvim-notify
        pkgs.vimPlugins.which-key-nvim
        (pkgs.vimPlugins.nvim-treesitter.withPlugins (p: [
          p.vim p.vimdoc p.zig p.c p.rust p.odin p.cpp p.go p.nix
          p.html p.css p.javascript p.json p.lua p.markdown p.python
          p.typescript p.bash
        ]))
        pkgs.vimPlugins.nvim-lspconfig
        pkgs.vimPlugins.oil-nvim
        pkgs.vimPlugins.oil-git-nvim
        pkgs.vimPlugins.direnv-vim
      ];
      customLuaRC = ''
    local opt = vim.opt

    -- ========================================================================
    -- OPTIONS
    -- ========================================================================

    opt.termguicolors = true
    opt.number = true
    opt.relativenumber = true
    opt.wrap = false
    opt.scrolloff = 10
    opt.sidescrolloff = 5

    opt.tabstop = 2
    opt.shiftwidth = 2
    opt.softtabstop = 2
    opt.expandtab = true
    opt.smartindent = true
    opt.autoindent = true

    opt.ignorecase = true
    opt.smartcase = true
    opt.hlsearch = true
    opt.incsearch = true

    opt.signcolumn = "yes"
    opt.colorcolumn = "80,120"
    opt.showmatch = true -- hightlights matching brackets
    opt.cmdheight = 1
    opt.completeopt = "menuone,noinsert,noselect"
    opt.showmode = false
    opt.pumheight = 10 -- popup menu height
    opt.pumblend = 10 -- popup menu transparency
    opt.conceallevel = 0 -- do not hide markup
    opt.concealcursor = "" -- do not hide cursorline in markup
    opt.synmaxcol = 300 -- syntax hightlighting limit
    opt.fillchars = { eob = " " } -- hide '~' on empty lines

    local undodir = vim.fn.expand("~/.vim/undodir")
    if
      vim.fn.isdirectory(undodir) == 0
    then
      vim.fn.mkdir(undodir, "p")
    end

    opt.backup = false
    opt.writebackup = false
    opt.swapfile = false
    opt.undofile = true
    opt.undodir = undodir
    opt.updatetime = 300
    opt.timeoutlen = 500
    opt.ttimeoutlen = 0
    opt.autoread = true
    opt.autowrite = false

    opt.hidden = true
    opt.errorbells = false
    opt.backspace = "indent,eol,start"
    opt.autochdir = false
    opt.iskeyword:append("-")
    opt.path:append("**")
    opt.selection = "inclusive"
    opt.mouse = "a"
    opt.clipboard:append("unnamedplus")
    opt.modifiable = true

    opt.guicursor = "n-v-c-sm:block,r-cr:hor20,o:hor50,a:blinkon0"

    -- Folding, requires treesitter available at runtime; safe fallback if not
    opt.foldmethod = "expr"
    opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
    opt.foldlevel = 99

    opt.splitbelow = true
    opt.splitright = true

    opt.wildmenu = true
    opt.wildmode = "longest:full,full"
    opt.diffopt:append("linematch:60")
    opt.redrawtime = 10000
    opt.maxmempattern = 20000

    -- ========================================================================
    -- KEYBINDINGS
    -- ========================================================================

    vim.g.mapleader = " "
    vim.g.maplocalleader = " "

    local keymap = vim.keymap

    keymap.set("n", "j", function()
      return vim.v.count == 0 and "gj" or "j"
    end, { expr = true, silent = true, desc = "Down (wrap-aware)" })
    keymap.set("n", "k", function()
      return vim.v.count == 0 and "gk" or "k"
    end, { expr = true, silent = true, desc = "Up (wrap-aware)" })

    keymap.set("n", "<Esc><Esc>", ":nohlsearch<CR>", { desc = "Clear search highlights" })

    keymap.set("n", "n", "nzzzv", { desc = "Next search result (centered)" })
    keymap.set("n", "N", "Nzzzv", { desc = "Next search result (centered)" })
    keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Half page down (centered)" })
    keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Half page down (centered)" })

    keymap.set("x", "<leader>p", '"_dP', { desc = "Paste without yanking" })
    keymap.set({ "n", "v" }, "<leader>x", '"_d', { desc = "Delete without yanking" })

    keymap.set("n", "<leader>bn", ":bnext<CR>", { desc = "Next buffer" })
    keymap.set("n", "<leader>bp", ":bprevious<CR>", { desc = "Previous buffer" })

    keymap.set("n", "<C-Up>", ":resize +2<CR>", { desc = "Increase window height" })
    keymap.set("n", "<C-Down>", ":resize -2<CR>", { desc = "Decrease window height" })
    keymap.set("n", "<C-Left>", ":vertical resize -2<CR>", { desc = "Decrease window width" })
    keymap.set("n", "<C-Right>", ":vertical resize +2<CR>", { desc = "Increase window width" })

    keymap.set("n", "<A-j>", ":m .+1<CR>==", { desc = "Move line down" })
    keymap.set("n", "<A-k>", ":m .-2<CR>==", { desc = "Move line up" })
    keymap.set("v", "<A-j>", ":m '>+1<CR>gv==gv", { desc = "Move selection down" })
    keymap.set("v", "<A-k>", ":m '<-2<CR>gv==gv", { desc = "Move selection up" })

    keymap.set("v", "<", "<gv", { desc = "Indent left and reselect" })
    keymap.set("v", ">", ">gv", { desc = "Indent right and reselect" })

    keymap.set("n", "J", "mzJ`z", { desc = "Join lines and keep cursor position" })

    keymap.set("n", "<leader>pa", function()
      local path = vim.fn.expand("%:p")
      vim.fn.setreg("+", path)
      print("file:", path)
    end, { desc = "Copy file full path" })

    keymap.set("n", "<leader>td", function()
      vim.diagnostic.enable(not vim.diagnostic.is_enabled())
    end, { desc = "Toggle diagnostics" })

    keymap.set("n", "<leader>dl", vim.diagnostic.open_float, { desc = "Show line diagnostics" })

    -- ========================================================================
    -- AUTOCMDS
    -- ========================================================================

    local augroup = vim.api.nvim_create_augroup("UserConfig", { clear = true })

    -- Highlight yanked text
    vim.api.nvim_create_autocmd("TextYankPost", {
      group = augroup,
      callback = function()
        vim.hl.on_yank()
      end
    })

    -- Restore last cursor position
    vim.api.nvim_create_autocmd("BufReadPost", {
      group = augroup,
      desc = "Restore last cursor position",
      callback = function()
        if vim.o.diff then
          return
        end

        local last_pos = vim.api.nvim_buf_get_mark(0, '"')
        local last_line = vim.api.nvim_buf_line_count(0)

        local row = last_pos[1]
        if row < 1 or row > last_line then
          return
        end

        pcall(vim.api.nvim_win_set_cursor, 0, last_pos)
      end,
    })

    vim.api.nvim_create_autocmd("FileType", {
      group = augroup,
      pattern = { "markdown", "text", "gitcommit" },
      callback = function()
        vim.opt_local.wrap = true
        vim.opt_local.linebreak = true
        vim.opt_local.spell = true
      end,
    })

    -- ========================================================================
    -- COLORSCHEME
    -- ========================================================================

    vim.cmd.colorscheme("koda")

    -- Tweaks: differences from the Helix koda variant
    local hl = vim.api.nvim_set_hl

    -- Pure black background (original koda uses #101010)
    hl(0, "Normal",   { fg = "#b0b0b0", bg = "#000000" })
    hl(0, "NormalNC", { bg = "#000000" })

    -- String/Character: muted green instead of white
    hl(0, "String",    { fg = "#8a9a7b" })
    hl(0, "Character", { fg = "#8a9a7b" })

    -- Success color: muted green instead of bright green (#86cd82 → #8aa372)
    -- DiffAdd bg is blend(success, bg, 0.2) recalculated for the new colors
    hl(0, "GitSignsAdd",  { fg = "#8aa372" })
    hl(0, "DiffAdd",      { fg = "#8aa372", bg = "#1b2117" })
    hl(0, "DiagnosticOk", { fg = "#8aa372" })

    -- ========================================================================
    -- PLUGINS
    -- ========================================================================
    local actions = require "telescope.actions"
    local builtin = require "telescope.builtin"
    require("telescope").setup{
      defaults = {
        preview = { treesitter = true },
        color_devicons = true,
        sorting_strategy = "ascending",
        borderchars = {
          "", -- top
          "", -- right
          "", -- bottom
          "", -- left
          "", -- top-left
          "", -- top-right
          "", -- bottom-right
          "", -- bottom-left
        },
        path_display = { "smart" },
        layout_config = {
          height = 100,
          width = 400,
          prompt_position = "top",
          preview_cutoff = 40,
        },
      },
      extensions = {
        fzf = {
          fuzzy = true,
          override_generic_sorter = true,
          override_file_sorter = true,
          case_mode = "smart_case",
        }
      },
    }

    require("telescope").load_extension("fzf")

    keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Telescope find files" })
    keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Telescope live grep" })
    keymap.set("n", "<leader>fss", builtin.grep_string, { desc = "Telescope grep selected string" })
    keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Telescope buffers" })
    keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Telescope help tags" })
    keymap.set("n", "<leader>fc", builtin.commands, { desc = "Telescope nvim commands" })
    keymap.set("n", "<leader>fmp", builtin.man_pages, { desc = "Telescope man pages" })
    keymap.set("n", "<leader>fvo", builtin.vim_options, { desc = "Telescope vim options" })
    keymap.set("n", "<leader>fr", builtin.registers, { desc = "Telescope registers" })
    keymap.set("n", "<leader>fau", builtin.autocommands, { desc = "Telescope autocommands" })
    keymap.set("n", "<leader>fzf", builtin.current_buffer_fuzzy_find, { desc = "Telescope fuzzy search current buffer" })
    keymap.set("n", "<leader>fd", builtin.diagnostics, { desc = "Telescope LSP diagnostics" })
    keymap.set("n", "<leader>flr", builtin.lsp_references, { desc = "Telescope LSP references" })
    keymap.set("n", "<leader>fli", builtin.lsp_implementations, { desc = "Telescope LSP implementations" })

    require("mini.ai").setup({})
    require("mini.comment").setup({})
    require("mini.move").setup({})
    require("mini.pairs").setup({})
    require("mini.splitjoin").setup({})
    require("mini.surround").setup({})
    require("mini.bracketed").setup({})
    require("mini.diff").setup({})
    -- mini.diff: match Helix koda diff colors
    -- Sign column (diff.plus/minus/delta)
    hl(0, "MiniDiffSignAdd",    { fg = "#8aa372" })
    hl(0, "MiniDiffSignChange", { fg = "#d9ba73" })
    hl(0, "MiniDiffSignDelete", { fg = "#ff7676" })
    -- Overlay: added/deleted/changed (bg = 20% blend of fg color into #000000)
    hl(0, "MiniDiffOverAdd",       { fg = "#8aa372", bg = "#1b2117" })
    hl(0, "MiniDiffOverDelete",    { fg = "#ff7676", bg = "#331717" })
    hl(0, "MiniDiffOverChange",    { fg = "#d9ba73", bg = "#2b2517" })
    hl(0, "MiniDiffOverChangeBuf", { fg = "#d9ba73", bg = "#2b2517" })
    -- Overlay: context lines (comment color on line bg)
    hl(0, "MiniDiffOverContext",    { fg = "#50585d", bg = "#272727" })
    hl(0, "MiniDiffOverContextBuf", { fg = "#50585d", bg = "#272727" })
    require("mini.git").setup({})
    require("mini.jump").setup({})
    require("mini.jump2d").setup({})
    require("mini.cursorword").setup({})
    -- require("mini.hipatterns").setup({})
    require("mini.icons").setup({})
    require("mini.icons").mock_nvim_web_devicons()
    require("mini.statusline").setup({})
    -- mini.statusline: match Helix koda statusline colors
    -- Mode pills (ui.statusline.normal/insert/select/…)
    hl(0, "MiniStatuslineModeNormal",  { fg = "#000000", bg = "#8ebeec", bold = true })
    hl(0, "MiniStatuslineModeInsert",  { fg = "#000000", bg = "#8a9a7b", bold = true })
    hl(0, "MiniStatuslineModeVisual",  { fg = "#000000", bg = "#d9ba73", bold = true })
    hl(0, "MiniStatuslineModeReplace", { fg = "#000000", bg = "#ff7676", bold = true })
    hl(0, "MiniStatuslineModeCommand", { fg = "#000000", bg = "#777777", bold = true })
    hl(0, "MiniStatuslineModeOther",   { fg = "#b0b0b0", bg = "#272727", bold = true })
    -- Statusline body sections (ui.statusline)
    hl(0, "MiniStatuslineFilename", { fg = "#b0b0b0", bg = "#000000" })
    hl(0, "MiniStatuslineDevinfo",  { fg = "#b0b0b0", bg = "#000000" })
    hl(0, "MiniStatuslineFileinfo", { fg = "#b0b0b0", bg = "#000000" })
    -- Inactive window statusline (ui.statusline.inactive)
    hl(0, "MiniStatuslineInactive", { fg = "#50585d", bg = "#000000" })
    require("mini.tabline").setup({})

    require("notify").setup({
      background_colour = "#000000",
      stages = "slide",
      timeout = 3000,
      max_width = 60,
    })
    vim.notify = require("notify")

    require("which-key").setup({})

    keymap.set("n", "<leader>?", function() require("which-key").show({ global = false }) end,
      { desc = "Buffer local keymaps (which-key)" })

    vim.api.nvim_create_autocmd("FileType", {
      group = augroup,
      callback = function(args)
        pcall(vim.treesitter.start, args.buf)
      end,
    })

    local lspconfig = require("lspconfig")
    local capabilities = vim.lsp.protocol.make_client_capabilities()

    local on_attach = function(_, buf)
      local k = function(keys, func, desc)
        keymap.set("n", keys, func, { buffer = buf, desc = desc })
      end
      k("gd", vim.lsp.buf.definition, "Go to definition (LSP)")
      k("gD", vim.lsp.buf.declaration, "Go to declaration (LSP)")
      k("gr", vim.lsp.buf.references, "References (LSP)")
      k("gi", vim.lsp.buf.implementation, "Go to implementation (LSP)")
      k("K", vim.lsp.buf.hover, "Hover docs (LSP)")
      k("<leader>rn", vim.lsp.buf.rename, "Rename (LSP)")
      k("<leader>ca", vim.lsp.buf.code_action, "Code action (LSP)")
      k("<leader>f", vim.lsp.buf.format, "Format (LSP)")
    end

    for _, server in ipairs({
      "zls",
      "rust_analyzer",
      "clangd",
      "nil_ls",
      "gopls",
      "pyright",
      "ts_ls",
      "lua_ls",
    }) do
      lspconfig[server].setup({
        on_attach = on_attach,
        capabilities = capabilities,
      })
    end

    vim.api.nvim_create_autocmd("BufWritePre", {
      group = augroup,
      callback = function()
        vim.lsp.buf.format({ async = false, timeout_ms = 2000 })
      end,
    })

    require("oil").setup({})

    keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory (Oil)"} )
    '';
    };
  };

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

