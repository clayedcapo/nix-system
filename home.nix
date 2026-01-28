# home.nix (Flakes version)
#
# DIFFERENCES FROM NON-FLAKE VERSION:
# ===================================
# 1. Can use specialArgs passed from flake.nix (pkgs-unstable, username, etc.)
# 2. No need to set home.username/homeDirectory if using variables
# 3. Can easily use packages from different channels

{ config, pkgs, lib, inputs, pkgs-unstable, username, ... }:
# ^
# | Arguments passed from flake.nix via extraSpecialArgs:
# | - inputs: All flake inputs
# | - pkgs-unstable: Unstable package set
# | - username: Your username variable

{
  # Home Manager needs to know about your user
  # Using the username variable from flake.nix
  home.username = username;
  home.homeDirectory = "/home/${username}";

  # Packages installed only for this user
  home.packages = with pkgs; [
    # Base
    alacritty
    tmux
    pkgs-unstable.helix

    ripgrep
    fd
    bat
    eza
    zoxide
    fzf
    jq

    # Languages
    # python3
    # rustup

    # GUI apps
    obsidian
    telegram-desktop
    vlc
    zathura
  ];

  # ============================================================================
  # SWAY CONFIGURATION
  # ============================================================================

  wayland.windowManager.sway = {
    enable = true;
    config = {
      modifier = "Mod4";
      terminal = "alacritty";
      menu = "tofi-drun | xargs swaymsg exec --";

      startup = [
        { command = "mako"; }
        { command = "waybar"; }
        { command = "mkfifo $SWAYSOCK.wob && tail -f $SWAYSOCK.wob | wob"; }
      ];

      # Idle configuration with swaylock and display power management
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

      # Key bindings
      keybindings = let
        modifier = config.wayland.windowManager.sway.config.modifier;
      in {
        # Basic bindings
        "${modifier}+Return" = "exec ${pkgs.alacritty}/bin/alacritty";
        "${modifier}+Shift+q" = "kill";
        "${modifier}+d" = "exec ${pkgs.tofi}/bin/tofi-drun | xargs swaymsg exec --";
        "${modifier}+Shift+c" = "reload";
        "${modifier}+Shift+e" = "exec swaynag -t warning -m 'Exit sway?' -b 'Yes' 'swaymsg exit'";

        # Lock screen
        "${modifier}+l" = "exec ${pkgs.swaylock}/bin/swaylock -f";

        # Screenshots
        "Print" = "exec ${pkgs.grim}/bin/grim -g \"$(${pkgs.slurp}/bin/slurp)\" - | ${pkgs.wl-clipboard}/bin/wl-copy";
        "Shift+Print" = "exec ${pkgs.grim}/bin/grim - | ${pkgs.wl-clipboard}/bin/wl-copy";

        # Focus
        "${modifier}+Left" = "focus left";
        "${modifier}+Down" = "focus down";
        "${modifier}+Up" = "focus up";
        "${modifier}+Right" = "focus right";

        # Move windows
        "${modifier}+Shift+Left" = "move left";
        "${modifier}+Shift+Down" = "move down";
        "${modifier}+Shift+Up" = "move up";
        "${modifier}+Shift+Right" = "move right";

        # Workspaces
        "${modifier}+1" = "workspace number 1";
        "${modifier}+2" = "workspace number 2";
        "${modifier}+3" = "workspace number 3";
        "${modifier}+4" = "workspace number 4";
        "${modifier}+5" = "workspace number 5";
        "${modifier}+6" = "workspace number 6";
        "${modifier}+7" = "workspace number 7";
        "${modifier}+8" = "workspace number 8";
        "${modifier}+9" = "workspace number 9";
        "${modifier}+0" = "workspace number 10";

        # Move to workspace
        "${modifier}+Shift+1" = "move container to workspace number 1";
        "${modifier}+Shift+2" = "move container to workspace number 2";
        "${modifier}+Shift+3" = "move container to workspace number 3";
        "${modifier}+Shift+4" = "move container to workspace number 4";
        "${modifier}+Shift+5" = "move container to workspace number 5";
        "${modifier}+Shift+6" = "move container to workspace number 6";
        "${modifier}+Shift+7" = "move container to workspace number 7";
        "${modifier}+Shift+8" = "move container to workspace number 8";
        "${modifier}+Shift+9" = "move container to workspace number 9";
        "${modifier}+Shift+0" = "move container to workspace number 10";

        # Layout
        "${modifier}+b" = "splith";
        "${modifier}+v" = "splitv";
        "${modifier}+s" = "layout stacking";
        "${modifier}+w" = "layout tabbed";
        "${modifier}+e" = "layout toggle split";
        "${modifier}+f" = "fullscreen";
        "${modifier}+Shift+space" = "floating toggle";
        "${modifier}+space" = "focus mode_toggle";

        # Audio controls with wob overlay
        "XF86AudioRaiseVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ && wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print $2*100}' > $SWAYSOCK.wob";
        "XF86AudioLowerVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- && wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print $2*100}' > $SWAYSOCK.wob";
        "XF86AudioMute" = "exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";

        # Brightness controls with wob overlay
        "XF86MonBrightnessUp" = "exec light -A 5 && light -G | cut -d'.' -f1 > $SWAYSOCK.wob";
        "XF86MonBrightnessDown" = "exec light -U 5 && light -G | cut -d'.' -f1 > $SWAYSOCK.wob";
      };

      output = {
        "*" = {
          bg = "#000000 solid_color";
        };
      };

      input = {
        "*" = {
          xkb_layout = "us";
        };

        "type:touchpad" = {
          tap = "enabled";
          natural_scroll = "enabled";
          dwt = "enabled";
        };
      };

      window.commands = [
        {
          criteria = { app_id = "^.*"; };
          command = "inhibit_idle fullscreen";
        }
      ];
    };

    extraConfig = ''
      # Add any additional sway config here
    '';
  };

  # ============================================================================
  # WAYBAR CONFIGURATION
  # ============================================================================

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

  # ============================================================================
  # ALACRITTY CONFIGURATION
  # ============================================================================

  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        opacity = 0.95;
        padding = {
          x = 10;
          y = 10;
        };
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

  # ============================================================================
  # MAKO (Notification Daemon)
  # ============================================================================

  services.mako = {
    enable = true;
    backgroundColor = "#1e1e2e";
    textColor = "#cdd6f4";
    borderColor = "#89b4fa";
    borderRadius = 5;
    borderSize = 2;
    defaultTimeout = 5000;
    width = 300;
    height = 100;
    margin = "10";
    padding = "10";
    font = "JetBrainsMono Nerd Font 10";
  };

  # ============================================================================
  # SWAYLOCK
  # ============================================================================

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

  # ============================================================================
  # GIT
  # ============================================================================

  programs.git = {
    enable = true;
    userName = "Ilya Sergeev";
    userEmail = "wesunnn2@gmail.com";
  };

  # ============================================================================
  # ADDITIONAL PROGRAMS WITH HOME MANAGER
  # ============================================================================

  # EXAMPLE: Use unstable version of a program
  # programs.neovim = {
  #   enable = true;
  #   package = pkgs-unstable.neovim;  # Use unstable neovim
  # };

  # EXAMPLE: Firefox with specific settings
  # programs.firefox = {
  #   enable = true;
  #   package = pkgs-unstable.firefox;  # Latest Firefox
  #   profiles.default = {
  #     settings = {
  #       "browser.startup.homepage" = "https://nixos.org";
  #     };
  #   };
  # };

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # Home Manager version
  home.stateVersion = "24.11";
}

# MIXING STABLE AND UNSTABLE PACKAGES
# ====================================
# With flakes, you can easily mix packages from different channels:
#
# home.packages = with pkgs; [
#   # Stable packages (24.11)
#   firefox
#   thunderbird
#
#   # Unstable packages (latest)
#   pkgs-unstable.discord
#   pkgs-unstable.vscode
#   pkgs-unstable.neovim
# ];
#
# Or in program configs:
# programs.alacritty = {
#   enable = true;
#   package = pkgs-unstable.alacritty;  # Use latest alacritty
# };

# ACCESSING FLAKE INPUTS
# =======================
# You can access other flake inputs if needed:
#
# Example: Using NUR (Nix User Repository) if added to flake.nix
# home.packages = [
#   inputs.nur.repos.some-user.some-package
# ];

# HOME MANAGER AS STANDALONE
# ===========================
# If you use standalone Home Manager (not as NixOS module):
#
# Build with:
#   home-manager switch --flake .#yourusername
#
# The flake.nix would have:
#   homeConfigurations.yourusername = home-manager.lib.homeManagerConfiguration {
#     inherit pkgs;
#     modules = [ ./home.nix ];
#   };
