# =============================================================================
# HOME MANAGER CONFIGURATION
# =============================================================================
# User-specific configuration managed by Home Manager
# This file is imported by flake.nix as a NixOS module
{ config, pkgs, lib, inputs, pkgs-unstable, username, ... }:
# ^
# | Arguments passed from flake.nix via extraSpecialArgs:
# | - config: Home Manager configuration (for self-references)
# | - pkgs: The nixpkgs package set (stable)
# | - lib: NixOS/Home Manager library functions
# | - inputs: All flake inputs (for custom packages)
# | - pkgs-unstable: Unstable package set (for latest versions)
# | - username: Your username variable
{
  # ===========================================================================
  # USER SETTINGS
  # ===========================================================================
  home.username = username;
  home.homeDirectory = "/home/${username}";

  # ---------------------------------------------------------------------------
  # Session Variables
  # ---------------------------------------------------------------------------
  home.sessionVariables = {
    BROWSER = "vivaldi";
    DELTA_PAGER = "less -R";  # Enable scrolling in `git diff` with delta
  };

  # ===========================================================================
  # PACKAGES
  # ===========================================================================
  home.packages = with pkgs; [
    # -------------------------------------------------------------------------
    # Base Tools
    # -------------------------------------------------------------------------
    alacritty
    tmux
    jujutsu
    gnupg

    # -------------------------------------------------------------------------
    # Nix Ecosystem Tools
    # -------------------------------------------------------------------------
    nix-output-monitor  # Prettier build output with dependency graph (nom)
    hydra-check         # Check Hydra CI for package build status
    nix-index           # Locate packages providing a file (nix-locate)
    nix-init            # Generate Nix derivations from URLs
    nix-melt            # Ranger-like flake.lock viewer
    nix-tree            # TUI to visualize derivation dependency graphs

    # -------------------------------------------------------------------------
    # Development Tools
    # -------------------------------------------------------------------------
    # NOTE: Language toolchains should be in per-project dev shells, not here
    # See dev-environments-guide.md for the recommended workflow
    gitleaks  # Scan git repos for secrets
    k6        # Load testing tool
    devbox    # Simplified dev environments (alternative to raw Nix shells)

    # -------------------------------------------------------------------------
    # Database Clients
    # -------------------------------------------------------------------------
    sqlite
    pgcli     # PostgreSQL CLI with auto-completion and syntax highlighting

    # -------------------------------------------------------------------------
    # GUI Applications
    # -------------------------------------------------------------------------
    vivaldi
    obsidian
    telegram-desktop
    zathura
    zoom-us

    # -------------------------------------------------------------------------
    # Multimedia
    # -------------------------------------------------------------------------
    ffmpeg-full
    vlc
    imv          # Simple image viewer for Wayland

    # -------------------------------------------------------------------------
    # Miscellaneous
    # -------------------------------------------------------------------------
    astroterm  # Terminal planetarium
  ];

  # ===========================================================================
  # CLI TOOLS
  # ===========================================================================
  # ---------------------------------------------------------------------------
  # eza - Modern ls replacement
  # ---------------------------------------------------------------------------
  programs.eza = {
    enable = true;
    enableZshIntegration = true;   # Creates `ls` alias
    enableBashIntegration = true;
    git = true;       # Show git status for files
    colors = "always";
    icons = "auto";
  };

  # ---------------------------------------------------------------------------
  # bat - Cat with syntax highlighting
  # ---------------------------------------------------------------------------
  # TODO: Add shell integrations from https://github.com/sharkdp/bat#integration-with-other-tools
  # Examples: man pages colorization, --help colorization, git diff integration
  programs.bat = {
    enable = true;
    config = {
      theme = "ansi";
      pager = "less -KFR";  # K=quit on Ctrl+C, F=quit if fits screen, R=raw control chars
    };
  };

  # ---------------------------------------------------------------------------
  # fzf - Fuzzy finder
  # ---------------------------------------------------------------------------
  # Keybindings enabled by shell integration:
  #   - Ctrl+T: Insert file paths
  #   - Ctrl+R: Search shell history
  #   - Alt+C: cd into directories
  #   - Tab: Enhanced completion for many commands
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;

    defaultCommand = "fd --type f --color=always";
    defaultOptions = [
      "--style full"
      "--preview='bat --color=always --style=numbers --line-range=:500 {}'"
    ];

    # Alt+C configuration (directory navigation)
    changeDirWidgetCommand = "fd --type d --color=always";
    changeDirWidgetOptions = [
      "--style full"
      "--preview 'tree -C {} | head -200'"
    ];

    # Ctrl+T configuration (file selection)
    fileWidgetCommand = "fd --type f";
    # fileWidgetOptions = [ ];

    # Ctrl+R configuration (history search)
    # historyWidgetOptions = [ ];
  };

  # ---------------------------------------------------------------------------
  # tealdeer - Fast tldr client
  # ---------------------------------------------------------------------------
  programs.tealdeer = {
    enable = true;
    enableAutoUpdates = false;  # Manual updates with `tldr --update`
    settings = {
      display = {
        compact = false;
        pager = true;
      };
    };
  };

  # ---------------------------------------------------------------------------
  # zoxide - Smarter cd command
  # ---------------------------------------------------------------------------
  # Commands: `z` (jump), `zi` (interactive with fzf)
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    # options = [ ];  # Additional options for `zoxide init`
  };

  # ---------------------------------------------------------------------------
  # fastfetch - System information tool
  # ---------------------------------------------------------------------------
  programs.fastfetch = {
    enable = true;
    settings = {
      logo = {
        source = "nixos_small";
      };
    };
  };

  # TODO: Consider atuin for shell history (https://github.com/atuinsh/atuin)
  # programs.atuin = { };
  #
  # ===========================================================================
  # SHELL CONFIGURATION
  # ===========================================================================
  # TODO: Configure zsh with:
  #   - Prompt theme (starship or powerlevel10k)
  #   - Plugins (syntax highlighting, autosuggestions)
  #   - Custom aliases and functions
  #   - History configuration
  #
  # programs.zsh = {
  #   enable = true;
  #   autosuggestion.enable = true;
  #   syntaxHighlighting.enable = true;
  # };
  #
  # ===========================================================================
  # SWAY (Wayland Compositor)
  # ===========================================================================
  # System-level Sway settings are in configuration.nix (programs.sway)
  # This configures user-specific behavior, keybindings, and appearance
  wayland.windowManager.sway = {
    enable = true;

    config = {
      # -----------------------------------------------------------------------
      # General Settings
      # -----------------------------------------------------------------------
      modifier = "Mod4";  # Super/Windows key
      terminal = "alacritty";
      menu = "tofi-drun | xargs swaymsg exec --";

      # -----------------------------------------------------------------------
      # Startup Applications
      # -----------------------------------------------------------------------
      startup = [
        { command = "mako"; }    # Notification daemon
        { command = "waybar"; }  # Status bar
        # wob: Wayland Overlay Bar for volume/brightness feedback
        { command = "mkfifo $SWAYSOCK.wob && tail -f $SWAYSOCK.wob | wob"; }
      ];

      # -----------------------------------------------------------------------
      # Idle and Lock Configuration
      # -----------------------------------------------------------------------
      # 5 min: lock screen, 10 min: turn off display
      idle = [
        {
          timeout = 300;
          command = "${pkgs.swaylock}/bin/swaylock -f";
        }
        {
          timeout = 600;
          command = "${pkgs.sway}/bin/swaymsg 'output * dpms off'";
          resumeCommand = "${pkgs.sway}/bin/swaymsg 'output * dpms on'";
        }
      ];

      # -----------------------------------------------------------------------
      # Key Bindings
      # -----------------------------------------------------------------------
      keybindings = let
        mod = config.wayland.windowManager.sway.config.modifier;
      in {
        # Basic
        "${mod}+Return" = "exec ${pkgs.alacritty}/bin/alacritty";
        "${mod}+Shift+q" = "kill";
        "${mod}+d" = "exec ${pkgs.tofi}/bin/tofi-drun | xargs swaymsg exec --";
        "${mod}+Shift+c" = "reload";
        "${mod}+Shift+e" = "exec swaynag -t warning -m 'Exit sway?' -b 'Yes' 'swaymsg exit'";

        # Lock screen
        "${mod}+l" = "exec ${pkgs.swaylock}/bin/swaylock -f";

        # Screenshots (to clipboard)
        "Print" = "exec ${pkgs.grim}/bin/grim -g \"$(${pkgs.slurp}/bin/slurp)\" - | ${pkgs.wl-clipboard}/bin/wl-copy";
        "Shift+Print" = "exec ${pkgs.grim}/bin/grim - | ${pkgs.wl-clipboard}/bin/wl-copy";

        # Focus navigation
        "${mod}+Left" = "focus left";
        "${mod}+Down" = "focus down";
        "${mod}+Up" = "focus up";
        "${mod}+Right" = "focus right";

        # Move windows
        "${mod}+Shift+Left" = "move left";
        "${mod}+Shift+Down" = "move down";
        "${mod}+Shift+Up" = "move up";
        "${mod}+Shift+Right" = "move right";

        # Workspaces
        "${mod}+1" = "workspace number 1";
        "${mod}+2" = "workspace number 2";
        "${mod}+3" = "workspace number 3";
        "${mod}+4" = "workspace number 4";
        "${mod}+5" = "workspace number 5";
        "${mod}+6" = "workspace number 6";
        "${mod}+7" = "workspace number 7";
        "${mod}+8" = "workspace number 8";
        "${mod}+9" = "workspace number 9";
        "${mod}+0" = "workspace number 10";

        # Move container to workspace
        "${mod}+Shift+1" = "move container to workspace number 1";
        "${mod}+Shift+2" = "move container to workspace number 2";
        "${mod}+Shift+3" = "move container to workspace number 3";
        "${mod}+Shift+4" = "move container to workspace number 4";
        "${mod}+Shift+5" = "move container to workspace number 5";
        "${mod}+Shift+6" = "move container to workspace number 6";
        "${mod}+Shift+7" = "move container to workspace number 7";
        "${mod}+Shift+8" = "move container to workspace number 8";
        "${mod}+Shift+9" = "move container to workspace number 9";
        "${mod}+Shift+0" = "move container to workspace number 10";

        # Layout
        "${mod}+b" = "splith";
        "${mod}+v" = "splitv";
        "${mod}+s" = "layout stacking";
        "${mod}+w" = "layout tabbed";
        "${mod}+e" = "layout toggle split";
        "${mod}+f" = "fullscreen";
        "${mod}+Shift+space" = "floating toggle";
        "${mod}+space" = "focus mode_toggle";

        # Audio (with wob overlay feedback)
        "XF86AudioRaiseVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ && wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print $2*100}' > $SWAYSOCK.wob";
        "XF86AudioLowerVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- && wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print $2*100}' > $SWAYSOCK.wob";
        "XF86AudioMute" = "exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";

        # Brightness (with wob overlay feedback)
        "XF86MonBrightnessUp" = "exec light -A 5 && light -G | cut -d'.' -f1 > $SWAYSOCK.wob";
        "XF86MonBrightnessDown" = "exec light -U 5 && light -G | cut -d'.' -f1 > $SWAYSOCK.wob";
      };

      # -----------------------------------------------------------------------
      # Output Configuration
      # -----------------------------------------------------------------------
      output = {
        "*" = {
          bg = "#000000 solid_color";
        };
      };

      # -----------------------------------------------------------------------
      # Input Configuration
      # -----------------------------------------------------------------------
      input = {
        "*" = {
          xkb_layout = "us";
        };

        "type:touchpad" = {
          tap = "enabled";
          natural_scroll = "enabled";
          dwt = "enabled";  # Disable while typing
        };
      };

      # -----------------------------------------------------------------------
      # Window Rules
      # -----------------------------------------------------------------------
      window.commands = [
        {
          # Prevent screen from going idle when any app is fullscreen
          criteria = { app_id = "^.*"; };
          command = "inhibit_idle fullscreen";
        }
      ];
    };

    extraConfig = ''
      # Additional raw sway config can go here
    '';
  };

  # ===========================================================================
  # WAYBAR (Status Bar)
  # ===========================================================================
  programs.waybar = {
    enable = true;

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 30;

        modules-left = [ "sway/workspaces" "sway/mode" ];
        modules-center = [ "sway/window" ];
        modules-right = [
          "pulseaudio"
          "network"
          "cpu"
          "memory"
          "temperature"
          "battery"
          "clock"
          "tray"
        ];

        "sway/workspaces" = {
          disable-scroll = true;
          all-outputs = true;
        };

        "sway/mode" = {
          format = "<span style=\"italic\">{}</span>";
        };

        "sway/window" = {
          max-length = 50;
        };

        "clock" = {
          format = "{:%Y-%m-%d %H:%M}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        };

        "cpu" = {
          format = "  {usage}%";
          tooltip = false;
        };

        "memory" = {
          format = "  {}%";
        };

        "temperature" = {
          critical-threshold = 80;
          format = "{icon} {temperatureC}°C";
          format-icons = [ "" "" "" ];
        };

        "battery" = {
          states = {
            warning = 30;
            critical = 15;
          };
          format = "{icon} {capacity}%";
          format-charging = " {capacity}%";
          format-plugged = " {capacity}%";
          format-icons = [ "" "" "" "" "" ];
        };

        "network" = {
          format-wifi = "  {essid} ({signalStrength}%)";
          format-ethernet = "  {ifname}";
          format-disconnected = "⚠  Disconnected";
          tooltip-format = "{ifname}: {ipaddr}/{cidr}";
        };

        "pulseaudio" = {
          format = "{icon} {volume}%";
          format-muted = "  Muted";
          format-icons = {
            headphone = "";
            hands-free = "";
            headset = "";
            default = [ "" "" "" ];
          };
          on-click = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        };

        "tray" = {
          spacing = 10;
        };
      };
    };

    # Catppuccin-inspired styling
    style = ''
      * {
        border: none;
        border-radius: 0;
        font-family: "JetBrainsMono Nerd Font";
        font-size: 13px;
        min-height: 0;
      }

      window#waybar {
        background-color: rgba(30, 30, 46, 0.9);
        color: #cdd6f4;
        transition-property: background-color;
        transition-duration: 0.5s;
      }

      #workspaces button {
        padding: 0 5px;
        color: #cdd6f4;
        background-color: transparent;
      }

      #workspaces button.focused {
        background-color: rgba(137, 180, 250, 0.3);
      }

      #workspaces button.urgent {
        background-color: #f38ba8;
      }

      #clock,
      #battery,
      #cpu,
      #memory,
      #temperature,
      #network,
      #pulseaudio,
      #tray,
      #mode,
      #window {
        padding: 0 10px;
      }

      #battery.charging {
        color: #a6e3a1;
      }

      #battery.warning:not(.charging) {
        color: #f9e2af;
      }

      #battery.critical:not(.charging) {
        color: #f38ba8;
        animation-name: blink;
        animation-duration: 0.5s;
        animation-timing-function: linear;
        animation-iteration-count: infinite;
        animation-direction: alternate;
      }

      @keyframes blink {
        to {
          background-color: #f38ba8;
          color: #1e1e2e;
        }
      }
    '';
  };

  # ===========================================================================
  # ALACRITTY (Terminal Emulator)
  # ===========================================================================
  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        opacity = 0.95;
        padding = { x = 10; y = 10; };
      };

      font = {
        normal = {
          family = "JetBrainsMono Nerd Font";
          style = "Regular";
        };
        size = 11.0;
      };

      colors = {
        primary = {
          background = "#1e1e2e";
          foreground = "#cdd6f4";
        };
      };
    };
  };

  # ===========================================================================
  # HELIX (Text Editor)
  # ===========================================================================
  # TODO: Configure Helix with:
  #   - Theme (catppuccin or kanso)
  #   - LSP configurations
  #   - Custom keybindings
  #
  # programs.helix = {
  #   enable = true;
  #   settings = {
  #     theme = "catppuccin_mocha";
  #     editor = {
  #       line-number = "relative";
  #       cursor-shape.insert = "bar";
  #     };
  #   };
  # };
  #
  # ===========================================================================
  # NOTIFICATIONS (Mako)
  # ===========================================================================
  services.mako = {
    enable = true;
    backgroundColor = "#1e1e2e";
    textColor = "#cdd6f4";
    borderColor = "#89b4fa";
    borderRadius = 5;
    borderSize = 2;
    defaultTimeout = 5000;  # 5 seconds
    width = 300;
    height = 100;
    margin = "10";
    padding = "10";
    font = "JetBrainsMono Nerd Font 10";
  };

  # ===========================================================================
  # SWAYLOCK (Screen Locker)
  # ===========================================================================
  programs.swaylock = {
    enable = true;
    settings = {
      color = "1e1e2e";
      font-size = 24;
      indicator-idle-visible = false;
      indicator-radius = 100;
      line-color = "1e1e2e";
      show-failed-attempts = true;
    };
  };

  # ===========================================================================
  # GIT
  # ===========================================================================
  # TODO: Add delta for better diffs, aliases, signing
  programs.git = {
    enable = true;
    userName = "Ilya Sergeev";
    userEmail = "wesunnn2@gmail.com";

    # TODO: Additional useful git config
    # delta.enable = true;  # Better diff viewer
    # extraConfig = {
    #   init.defaultBranch = "main";
    #   pull.rebase = true;
    #   push.autoSetupRemote = true;
    # };
  };

  # ===========================================================================
  # YAZI (File Manager)
  # ===========================================================================
  # TODO: Configure Yazi file manager
  # programs.yazi = {
  #   enable = true;
  #   enableZshIntegration = true;  # Shell wrapper for cd on exit
  # };
  #
  # ===========================================================================
  # GTK THEMING
  # ===========================================================================
  # GTK application appearance settings
  gtk = {
    enable = true;
    font = {
      name = "AporeticSerifMonoNerdFont";
      package = inputs.aporetic-nerd-font.packages.${pkgs.system}.default;
      size = 11;
    };

    # NOTE: gtk.colorScheme is deprecated in newer Home Manager versions
    # Use gtk3/gtk4 extraConfig or dconf settings instead
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
  };

  # ===========================================================================
  # HOME MANAGER
  # ===========================================================================
  # Let Home Manager manage itself (for standalone usage)
  programs.home-manager.enable = true;

  # ===========================================================================
  # STATE VERSION
  # ===========================================================================
  # DON'T CHANGE after initial setup
  # This ensures Home Manager compatibility across upgrades
  home.stateVersion = "24.11";
}
# =============================================================================
# TIPS & TRICKS
# =============================================================================
#
# MIXING STABLE AND UNSTABLE PACKAGES
# -----------------------------------
# With flakes, you can easily mix packages from different channels:
#
#   home.packages = with pkgs; [
#     firefox              # From stable (24.11)
#     pkgs-unstable.neovim # From unstable (latest)
#   ];
#
# Or in program configs:
#
#   programs.alacritty = {
#     enable = true;
#     package = pkgs-unstable.alacritty;  # Use latest version
#   };
#
# ACCESSING FLAKE INPUTS
# ----------------------
# You can access other flake inputs if needed:
#
#   home.packages = [
#     inputs.nur.repos.some-user.some-package
#   ];
#
# PROGRAMS VS PACKAGES
# --------------------
# - programs.*: Installs AND configures (preferred when available)
# - home.packages: Just installs (use for apps without HM modules)
#
# Check available modules: https://home-manager-options.extranix.com/
#
# STANDALONE HOME MANAGER
# -----------------------
# If you use standalone Home Manager (not as NixOS module):
#
#   home-manager switch --flake .#yourusername
#
# The flake.nix would have:
#
#   homeConfigurations.yourusername = home-manager.lib.homeManagerConfiguration {
#     inherit pkgs;
#     modules = [ ./home.nix ];
#   };
