# =============================================================================
# HOME MANAGER CONFIGURATION
# =============================================================================
# User-specific configuration managed by Home Manager
# This file is imported by flake.nix as a NixOS module
{ config, pkgs, lib, inputs, pkgs-unstable, username, hostname, ... }:
# ^
# | Arguments passed from flake.nix via extraSpecialArgs:
# | - config: Home Manager configuration (for self-references)
# | - pkgs: The nixpkgs package set (stable)
# | - lib: NixOS/Home Manager library functions
# | - inputs: All flake inputs (for custom packages)
# | - pkgs-unstable: Unstable package set (for latest versions)
# | - username: User's profile name
# | - hostname: Host machine name
{
  # ===========================================================================
  # USER SETTINGS
  # ===========================================================================
  home.username = username;
  home.homeDirectory = "/home/${username}";

  # Wallpaper
  home.file.".config/wallpaper/landscape.jpg".source = ./wallpaper/landscape.jpg;

  home.shell.enableZshIntegration = true;
  home.shell.enableBashIntegration = true;

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
    # NOTE: Most of them installed system-wide (hence specified in `configuraton.nix`)
    alacritty
    tmux
    jujutsu

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
    # NOTE: Dev toolchains should be in per-project dev shells, not here
    gitleaks  # Scan git repos for secrets
    k6        # Load testing tool
    devbox    # Simplified dev environments (alternative to raw Nix shells)
    gh        # GitHub CLI
    glab      # GitLab CLI

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
    zathuraPkgs.zathura_pdf_poppler # poppler pdf support
    zoom-us

    # -------------------------------------------------------------------------
    # Multimedia
    # -------------------------------------------------------------------------
    ffmpeg-full
    vlc
    imv          # Simple image viewer for Wayland
    pavucontrol
    pandoc
    imagemagick

    # -------------------------------------------------------------------------
    # Miscellaneous
    # -------------------------------------------------------------------------
    astroterm  # Terminal planetarium
    iwe # LSP for Markdown
    xdg-utils # cli tools that assist applications with desktop integration tasks
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
  programs.bat = {
    enable = true;
    config = {
      theme = "ansi";
      pager = "less -KFR";  # K=quit on Ctrl+C, F=quit if fits screen, R=raw control chars
    };
    # NOTE: Maybe consider to use analogous shell scripts themselves for more flexibility
    extraPackages = with pkgs.bat-extras; [ batdiff batman batgrep batwatch ];
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
  # fd - Fast and simple alternative to find
  # ---------------------------------------------------------------------------
  programs.fd = {
    enable = true;
    extraOptions = [
      "-X" "bat"
    ];
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
  # MAN PAGES
  # ===========================================================================
  # NOTE: `documentation` entry in `configuration.nix` is system-wide, this option sets up man pages for user space
  programs.man = {
    enable = true;
    generateCaches = true;
  };

  # Install the configuration manual page (can be reached by `man home-configuration.nix`)
  manual.manpages.enable = true;

  # ===========================================================================
  # SHELL CONFIGURATION (ZSH)
  # ===========================================================================
  programs.zsh = {
    enable = true;

    # ---------------------------------------------------------------------------
    # Core Features
    # ---------------------------------------------------------------------------
    enableCompletion = true;           # Enable tab completion
    autosuggestion.enable = true;      # Fish-like autosuggestions from history
    syntaxHighlighting.enable = true;  # Syntax highlighting for commands

    # ---------------------------------------------------------------------------
    # Environment Variables
    # ---------------------------------------------------------------------------
    sessionVariables = {
      TERMINAL = "alacritty";
      BROWSER = "vivaldi";
    };

    # ---------------------------------------------------------------------------
    # History Configuration
    # ---------------------------------------------------------------------------
    history = {
      path = "${config.home.homeDirectory}/.zsh_history";
      save = 100000;              # Number of commands to save
      size = 100000;              # Number of commands to keep in memory
      share = true;               # Share history between sessions
      extended = true;            # Save timestamps
      ignoreDups = true;          # Don't save duplicate commands
      ignoreSpace = true;         # Don't save commands starting with space
      ignoreAllDups = true;       # Remove all earlier duplicates when adding new
      expireDuplicatesFirst = true;  # Expire duplicates first when trimming
    };

    # ---------------------------------------------------------------------------
    # Pure Prompt (Minimal, fast zsh prompt)
    # ---------------------------------------------------------------------------
    # https://github.com/sindresorhus/pure
    plugins = [
      {
        name = "pure";
        src = pkgs.fetchFromGitHub {
          owner = "sindresorhus";
          repo = "pure";
          rev = "v1.23.0";
          sha256 = "sha256-BmQO4xqd/3QnpLUitD2obVxL0UulpboT8jGNEh4ri8k=";
        };
        file = "pure.zsh";
      }
    ];

    # ---------------------------------------------------------------------------
    # Shell Options
    # ---------------------------------------------------------------------------
    # See: https://zsh.sourceforge.io/Doc/Release/Options.html
    initContent = ''
      # -----------------------------------------------------------------------
      # Pure Prompt Configuration
      # -----------------------------------------------------------------------
      # Initialize prompt system
      fpath+=("$HOME/.nix-profile/share/zsh/site-functions")
      autoload -U promptinit; promptinit

      # Pure prompt settings (set BEFORE loading prompt)
      zstyle ':prompt:pure:git:stash' show yes        # Show stash indicator
      zstyle ':prompt:pure:path' color white          # Path color (white for emphasis)
      zstyle ':prompt:pure:prompt:success' color 242  # Prompt symbol (gray)
      zstyle ':prompt:pure:prompt:error' color red    # Prompt when error
      zstyle ':prompt:pure:git:branch' color 242      # Git branch (gray)
      zstyle ':prompt:pure:git:dirty' color yellow    # Dirty repo indicator
      zstyle ':prompt:pure:execution_time' color blue # Command execution time

      prompt pure

      # -----------------------------------------------------------------------
      # Navigation & Directory Options
      # -----------------------------------------------------------------------
      setopt AUTO_CD              # Type directory name to cd into it
      setopt AUTO_PUSHD           # Make cd push old directory onto stack
      setopt PUSHD_IGNORE_DUPS    # Don't push duplicates onto stack
      setopt PUSHD_SILENT         # Don't print directory stack after pushd/popd
      setopt PUSHD_MINUS          # Swap meaning of +/- for directory stack

      # -----------------------------------------------------------------------
      # Globbing & Pattern Matching
      # -----------------------------------------------------------------------
      setopt EXTENDED_GLOB        # Use extended globbing (#, ~, ^)
      setopt GLOB_DOTS            # Include dotfiles in glob matches
      setopt NOMATCH              # Error if glob pattern has no matches
      setopt NO_CASE_GLOB         # Case-insensitive globbing

      # -----------------------------------------------------------------------
      # Completion Options
      # -----------------------------------------------------------------------
      setopt COMPLETE_IN_WORD     # Complete from both ends of word
      setopt ALWAYS_TO_END        # Move cursor to end after completion
      setopt AUTO_MENU            # Show completion menu on second tab
      setopt AUTO_LIST            # Automatically list choices on ambiguous completion
      setopt MENU_COMPLETE        # Insert first match immediately

      # Completion styling
      zstyle ':completion:*' menu select                           # Select completions with arrow keys
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'      # Case-insensitive completion
      zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"   # Colorize completions
      zstyle ':completion:*' group-name '''                        # Group completions by type
      zstyle ':completion:*:descriptions' format '%B%d%b'         # Bold group descriptions
      zstyle ':completion:*:warnings' format 'No matches found'   # Message when no matches

      # -----------------------------------------------------------------------
      # Input/Output Options
      # -----------------------------------------------------------------------
      setopt INTERACTIVE_COMMENTS # Allow comments in interactive shell
      setopt NO_BEEP              # Don't beep on errors
      setopt CORRECT              # Suggest corrections for commands (not args)
      setopt MULTIOS              # Perform multiple redirections

      # -----------------------------------------------------------------------
      # Job Control
      # -----------------------------------------------------------------------
      setopt NO_HUP               # Don't kill background jobs on exit
      setopt NO_CHECK_JOBS        # Don't warn about running jobs on exit
      setopt LONG_LIST_JOBS       # List jobs in long format

      # -----------------------------------------------------------------------
      # Aliases
      # -----------------------------------------------------------------------
      # Git shortcuts (gh is GitHub CLI, use g-prefixed for git)
      alias g='git'
      alias gs='git status'
      alias ga='git add'
      alias gc='git commit'
      alias gp='git push'
      alias gl='git pull'
      alias gd='git diff'
      alias gds='git diff --staged'
      alias gco='git checkout'
      alias gb='git branch'
      alias glog='git log --oneline --graph --all'

      # Directory navigation (complement zoxide)
      alias ..='cd ..'
      alias ...='cd ../..'
      alias ....='cd ../../..'
      alias d='dirs -v'  # Show directory stack with numbers

      # System shortcuts
      alias rebuild='sudo nixos-rebuild switch --flake ~/.config/nixos#${hostname}'
      alias rebuild-home='home-manager switch --flake ~/.config/nixos#${username}'
      alias nix-clean='nix-collect-garbage -d && sudo nix-collect-garbage -d'
      alias nix-search='nix search nixpkgs'

      # Safety nets
      alias rm='rm -i'
      alias cp='cp -i'
      alias mv='mv -i'

      # Quick edits
      alias zshrc='$EDITOR ~/.zshrc'
      alias helix='hx'  # hx is the actual binary name

      # -----------------------------------------------------------------------
      # Key Bindings
      # -----------------------------------------------------------------------
      # Emacs-style key bindings (default, but explicit)
      bindkey -e

      # Ctrl+U to delete from cursor to beginning of line (bash-style)
      bindkey '^U' backward-kill-line

      # Ctrl+arrows for word navigation
      bindkey '^[[1;5C' forward-word      # Ctrl+Right
      bindkey '^[[1;5D' backward-word     # Ctrl+Left

      # -----------------------------------------------------------------------
      # Functions
      # -----------------------------------------------------------------------
      # Quick directory creation and navigation
      mkcd() {
        mkdir -p "$1" && cd "$1"
      }

      # Extract archives automatically
      extract() {
        if [ -f "$1" ]; then
          case "$1" in
            *.tar.bz2) tar xjf "$1" ;;
            *.tar.gz)  tar xzf "$1" ;;
            *.bz2)     bunzip2 "$1" ;;
            *.rar)     unrar x "$1" ;;
            *.gz)      gunzip "$1" ;;
            *.tar)     tar xf "$1" ;;
            *.tbz2)    tar xjf "$1" ;;
            *.tgz)     tar xzf "$1" ;;
            *.zip)     unzip "$1" ;;
            *.Z)       uncompress "$1" ;;
            *.7z)      7z x "$1" ;;
            *)         echo "'$1' cannot be extracted" ;;
          esac
        else
          echo "'$1' is not a valid file"
        fi
      }

      # Find and cd into directory using fzf
      fcd() {
        local dir
        dir=$(fd --type d --hidden --exclude .git | fzf --preview 'tree -C {} | head -200')
        [ -n "$dir" ] && cd "$dir"
      }

      # -----------------------------------------------------------------------
      # Performance Optimization
      # -----------------------------------------------------------------------
      # Disable compinit check for faster startup (Home Manager handles this)
      skip_global_compinit=1
    '';

    # ---------------------------------------------------------------------------
    # Shell Aliases (declarative)
    # ---------------------------------------------------------------------------
    shellAliases = {
      # These complement the aliases in initExtra
      # Listed here for visibility in Home Manager config
      cat = "bat";           # Use bat instead of cat (syntax highlighting)
      ls = "eza";            # Already configured via programs.eza
      tree = "eza --tree";   # Tree view with eza
    };

    # ---------------------------------------------------------------------------
    # Directory Hashes
    # ---------------------------------------------------------------------------
    # Quick navigation: cd ~config, cd ~dots, etc.
    dirHashes = {
      config = "$HOME/.config";
      dots = "$HOME/.config/nixos";
      dl = "$HOME/Downloads";
      docs = "$HOME/Documents";
    };
  };

  # ===========================================================================
  # TMUX (Terminal Multiplexer)
  # ===========================================================================
  programs.tmux = {
    enable = true;

    # ---------------------------------------------------------------------------
    # Terminal Settings
    # ---------------------------------------------------------------------------
    terminal = "tmux-256color";      # Enable 256 color support
    historyLimit = 50000;            # Scrollback buffer size
    escapeTime = 10;                 # Reduce ESC delay (important for helix/vim)

    # ---------------------------------------------------------------------------
    # General Behavior
    # ---------------------------------------------------------------------------
    mouse = true;                    # Enable mouse support
    keyMode = "vi";                  # Vi-style key bindings in copy mode
    customPaneNavigationAndResize = true;  # Sensible pane navigation
    resizeAmount = 5;                # Resize panes by 5 cells

    # ---------------------------------------------------------------------------
    # Custom Configuration
    # ---------------------------------------------------------------------------
    extraConfig = ''
      # -----------------------------------------------------------------------
      # Terminal & Color Support
      # -----------------------------------------------------------------------
      set -as terminal-features ",xterm-256color:RGB"  # True color support
      set -g focus-events on                           # Enable focus events for vim

      # -----------------------------------------------------------------------
      # Window & Pane Settings
      # -----------------------------------------------------------------------
      # setw -g pane-base-index 1        # Start pane numbering at 1
      setw -g aggressive-resize on     # Smart window sizing
      set -g renumber-windows on       # Renumber windows when one is closed
      set -g set-titles on             # Set terminal title
      set -g set-titles-string "#T"    # Terminal title format

      # -----------------------------------------------------------------------
      # Status Bar Configuration
      # -----------------------------------------------------------------------
      set -g status-position bottom              # Status bar at bottom
      set -g status-justify absolute-centre      # Center window list
      set -g status-left-length 20
      set -g status-right-length 50

      # Status bar content
      set -g status-left '[#S] '                 # Session name
      set -g status-right \'\'                     # Empty right side (minimal)

      # Status bar colors (matching system theme)
      set -g status-style 'bg=#000000 fg=#b0b0b0'           # Black bg, gray text
      set -g window-status-current-style 'fg=#ffffff bold'  # White + bold for current
      set -g window-status-separator ' '                    # Window separator

      # -----------------------------------------------------------------------
      # Pane Border Colors
      # -----------------------------------------------------------------------
      set -g pane-border-style 'fg=#50585d'                 # Inactive pane border (comment gray)
      set -g pane-active-border-style 'fg=#8ebeec'          # Active pane border (info blue)

      # -----------------------------------------------------------------------
      # Message & Command Line Colors
      # -----------------------------------------------------------------------
      set -g message-style 'bg=#000000 fg=#ffffff bold'     # Command line messages
      set -g message-command-style 'bg=#000000 fg=#8ebeec'  # Command mode

      # -----------------------------------------------------------------------
      # Copy Mode Colors
      # -----------------------------------------------------------------------
      set -g mode-style 'bg=#8ebeec fg=#000000'             # Copy mode selection (blue bg)

      # -----------------------------------------------------------------------
      # Key Bindings - Pane Management
      # -----------------------------------------------------------------------
      # Split panes using | and - (more intuitive than % and ")
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      unbind '"'
      unbind %

      # New window in current path
      bind c new-window -c "#{pane_current_path}"

      # -----------------------------------------------------------------------
      # Key Bindings - Pane Navigation (Vim-style)
      # -----------------------------------------------------------------------
      # Smart pane switching with awareness of vim splits
      # Use Ctrl+hjkl to navigate panes (works with vim)
      is_vim="ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$'"
      bind -n C-h if-shell "$is_vim" "send-keys C-h"  "select-pane -L"
      bind -n C-j if-shell "$is_vim" "send-keys C-j"  "select-pane -D"
      bind -n C-k if-shell "$is_vim" "send-keys C-k"  "select-pane -U"
      bind -n C-l if-shell "$is_vim" "send-keys C-l"  "select-pane -R"

      # Restore Ctrl+l to clear screen (shadowed by above)
      bind C-l send-keys 'C-l'

      # -----------------------------------------------------------------------
      # Key Bindings - Pane Resizing
      # -----------------------------------------------------------------------
      # Resize panes with Prefix + Shift + hjkl
      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5

      # -----------------------------------------------------------------------
      # Key Bindings - Window Navigation
      # -----------------------------------------------------------------------
      # Quick window switching
      bind -n M-h previous-window    # Alt+h
      bind -n M-l next-window        # Alt+l

      # -----------------------------------------------------------------------
      # Key Bindings - Utility
      # -----------------------------------------------------------------------
      # Reload config
      bind r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded!"

      # Show environment variables
      bind E show-environment -g

      # Kill pane without confirmation
      bind x kill-pane

      # Toggle synchronize-panes (send commands to all panes)
      bind S set-window-option synchronize-panes\; display "Sync: #{?synchronize-panes,ON,OFF}"

      # -----------------------------------------------------------------------
      # Copy Mode (Vi-style)
      # -----------------------------------------------------------------------
      # Enter copy mode with Prefix + [
      bind [ copy-mode
      bind ] paste-buffer

      # Vi-style selection and copying
      bind -T copy-mode-vi v send-keys -X begin-selection
      bind -T copy-mode-vi y send-keys -X copy-selection-and-cancel
      bind -T copy-mode-vi C-v send-keys -X rectangle-toggle

      # Copy to system clipboard (requires wl-clipboard on Wayland)
      bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "wl-copy"

      # -----------------------------------------------------------------------
      # Activity & Monitoring
      # -----------------------------------------------------------------------
      set -g monitor-activity on       # Highlight windows with activity
      set -g visual-activity off       # Don't show message (status is enough)
      set -g bell-action none          # Don't react to bells

      # -----------------------------------------------------------------------
      # Session Management
      # -----------------------------------------------------------------------
      # Quick session switching
      bind -n M-s choose-session       # Alt+s to list sessions

      # -----------------------------------------------------------------------
      # Performance
      # -----------------------------------------------------------------------
      set -g display-time 2000         # Display messages for 2 seconds
      set -g status-interval 5         # Update status bar every 5 seconds
    '';

    # ---------------------------------------------------------------------------
    # Plugins (optional - uncomment to enable)
    # ---------------------------------------------------------------------------
    # plugins = with pkgs.tmuxPlugins; [
    #   {
    #     plugin = resurrect;          # Save/restore tmux sessions
    #     extraConfig = ''
    #       set -g @resurrect-strategy-nvim 'session'
    #       set -g @resurrect-capture-pane-contents 'on'
    #     '';
    #   }
    #   {
    #     plugin = continuum;          # Auto-save tmux sessions
    #     extraConfig = ''
    #       set -g @continuum-restore 'on'
    #       set -g @continuum-save-interval '15'
    #     '';
    #   }
    #   yank                           # Enhanced copy/paste
    #   sensible                       # Sensible defaults
    # ];
  };

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
      menu = "tofi-run | xargs swaymsg exec --";

      fonts = {
        names = [ "AporeticSerifMonoNerdFont" ];
        style = "Regular";
        size = 12.0;
      };

      # Vim-like directional keys
      left = "h";
      down = "j";
      up = "k";
      right = "l";

      floating.modifier = "Mod4";

      gaps = {
        inner = 0;
        outer = 0;
      };

      # -----------------------------------------------------------------------
      # Startup Applications
      # -----------------------------------------------------------------------
      startup = [
        { command = "mako"; }    # Notification daemon
        # wob: Wayland Overlay Bar for volume/brightness feedback
        { command = "rm -f $XDG_RUNTIME_DIR/wob.sock && mkfifo $XDG_RUNTIME_DIR/wob.sock && tail -f $XDG_RUNTIME_DIR/wob.sock | wob"; }
      ];

      # -----------------------------------------------------------------------
      # Key Bindings
      # -----------------------------------------------------------------------
      keybindings = let
        mod = config.wayland.windowManager.sway.config.modifier;
      in {
        # Basic
        "${mod}+Return" = "exec ${pkgs.alacritty}/bin/alacritty";
        "${mod}+Control+Return" = "exec vivaldi";
        "${mod}+q" = "kill";
        "${mod}+d" = "exec ${pkgs.tofi}/bin/tofi-run | xargs swaymsg exec --";
        "${mod}+Control+d" = "exec ${pkgs.tofi}/bin/tofi-drun | xargs swaymsg exec --";
        "${mod}+Control+r" = "reload";
        "${mod}+Control+e" = "exec swaynag -t warning -m 'You pressed the exit shortcut. Do you really want to exit sway? This will end your Wayland session.' -B 'Yes, exit sway' 'swaymsg exit'";

        # Lock screen (Shift+l since mod+l is used for vim-style focus right)
        "${mod}+Shift+l" = "exec ${pkgs.swaylock}/bin/swaylock -f";

        # Screenshots
        "Print" = "exec ${pkgs.grim}/bin/grim";  # Save screenshot
        "Shift+Print" = "exec ${pkgs.grim}/bin/grim - | ${pkgs.wl-clipboard}/bin/wl-copy";  # To clipboard

        # Focus navigation (vim keys)
        "${mod}+h" = "focus left";
        "${mod}+j" = "focus down";
        "${mod}+k" = "focus up";
        "${mod}+l" = "focus right";
        # Focus navigation (arrow keys)
        "${mod}+Left" = "focus left";
        "${mod}+Down" = "focus down";
        "${mod}+Up" = "focus up";
        "${mod}+Right" = "focus right";

        # Move windows (vim keys)
        "${mod}+Control+h" = "move left";
        "${mod}+Control+j" = "move down";
        "${mod}+Control+k" = "move up";
        "${mod}+Control+l" = "move right";
        # Move windows (arrow keys)
        "${mod}+Control+Left" = "move left";
        "${mod}+Control+Down" = "move down";
        "${mod}+Control+Up" = "move up";
        "${mod}+Control+Right" = "move right";

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
        "${mod}+Control+1" = "move container to workspace number 1";
        "${mod}+Control+2" = "move container to workspace number 2";
        "${mod}+Control+3" = "move container to workspace number 3";
        "${mod}+Control+4" = "move container to workspace number 4";
        "${mod}+Control+5" = "move container to workspace number 5";
        "${mod}+Control+6" = "move container to workspace number 6";
        "${mod}+Control+7" = "move container to workspace number 7";
        "${mod}+Control+8" = "move container to workspace number 8";
        "${mod}+Control+9" = "move container to workspace number 9";
        "${mod}+Control+0" = "move container to workspace number 10";

        # Layout
        "${mod}+b" = "splith";
        "${mod}+v" = "splitv";
        "${mod}+s" = "layout stacking";
        "${mod}+w" = "layout tabbed";
        "${mod}+e" = "layout toggle split";
        "${mod}+m" = "fullscreen";
        "${mod}+Control+space" = "floating toggle";
        "${mod}+space" = "focus mode_toggle";
        "${mod}+a" = "focus parent";

        # Scratchpad
        "${mod}+Control+minus" = "move scratchpad";
        "${mod}+minus" = "scratchpad show";

        # Resize mode
        "${mod}+r" = "mode resize";

        # Allsink mode (utilities)
        "${mod}+z" = "mode allsink";

        # Audio (with wob overlay feedback)
        "--locked XF86AudioMute" = "exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && (wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q MUTED && echo 0 > $XDG_RUNTIME_DIR/wob.sock) || wpctl get-volume @DEFAULT_AUDIO_SINK@ | sed 's/[^0-9]//g' > $XDG_RUNTIME_DIR/wob.sock";
        "--locked XF86AudioLowerVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%- && wpctl get-volume @DEFAULT_AUDIO_SINK@ | sed 's/[^0-9]//g' > $XDG_RUNTIME_DIR/wob.sock";
        "--locked XF86AudioRaiseVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%+ && wpctl get-volume @DEFAULT_AUDIO_SINK@ | sed 's/[^0-9]//g' > $XDG_RUNTIME_DIR/wob.sock";

        # Brightness (with wob overlay feedback)
        "--locked XF86MonBrightnessDown" = "exec brightnessctl set 5%- | sed -En 's/.*\\(([0-9]+)%\\).*/\\1/p' > $XDG_RUNTIME_DIR/wob.sock";
        "--locked XF86MonBrightnessUp" = "exec brightnessctl set 5%+ | sed -En 's/.*\\(([0-9]+)%\\).*/\\1/p' > $XDG_RUNTIME_DIR/wob.sock";
      };

      modes = {
        resize = {
          # Vim keys
          "h" = "resize shrink width 10px";
          "j" = "resize grow height 10px";
          "k" = "resize shrink height 10px";
          "l" = "resize grow width 10px";
          # Arrow keys
          "Left" = "resize shrink width 10px";
          "Down" = "resize grow height 10px";
          "Up" = "resize shrink height 10px";
          "Right" = "resize grow width 10px";
          # Exit
          "Return" = "mode default";
          "Escape" = "mode default";
        };

        allsink = {
          # p = color picker
          "p" = "exec wl-color-picker clipboard; mode default";
          # s = screenshot region to clipboard
          "s" = "exec ${pkgs.slurp}/bin/slurp | ${pkgs.grim}/bin/grim -g - - | ${pkgs.wl-clipboard}/bin/wl-copy; mode default";
          # Exit
          "Return" = "mode default";
          "Escape" = "mode default";
        };
      };

      # -----------------------------------------------------------------------
      # Output Configuration
      # -----------------------------------------------------------------------
      output = {
        "*" = {
          # TODO: This fails on system install, so figure out how to meitgate it later
          # bg = "~/.config/wallpaper/landscape.jpg fill";
        };
      };

      # -----------------------------------------------------------------------
      # Input Configuration
      # -----------------------------------------------------------------------
      input = {
        "type:keyboard" = {
          xkb_layout = "us,ru";
          xkb_options = "grp:win_space_toggle";
        };

        "type:touchpad" = {
          tap = "enabled";
          natural_scroll = "enabled";
          dwt = "enabled";  # Disable while typing
          middle_emulation = "enabled";
        };
      };

      # -----------------------------------------------------------------------
      # Colors and Borders
      # -----------------------------------------------------------------------
      colors = {
        focused = {
          border = "#b0b0b0";
          background = "#b0b0b0";
          text = "#000000";
          indicator = "#b0b0b0";
          childBorder = "#b0b0b0";
        };
        focusedInactive = {
          border = "#000000";
          background = "#000000";
          text = "#50585d";
          indicator = "#000000";
          childBorder = "#000000";
        };
        unfocused = {
          border = "#000000";
          background = "#000000";
          text = "#50585d";
          indicator = "#000000";
          childBorder = "#000000";
        };
      };

      window = {
        border = 2;
        titlebar = false;

        commands = [
          {
            # Prevent screen from going idle when any app is fullscreen
            criteria = { app_id = "^.*"; };
            command = "inhibit_idle fullscreen";
          }
          {
            # Float pavucontrol
            criteria = { app_id = "pavucontrol"; };
            command = "floating enable";
          }
        ];
      };

      # -----------------------------------------------------------------------
      # Bar
      # -----------------------------------------------------------------------
      bars = [{
        command = "waybar";
        position = "top";
      }];
    };

    extraConfig = ''
      # Host-specific output configuration
      # Note: These settings only apply if the output exists
      # Main laptop (eDP-1): 144Hz display with tearing support for gaming
      output eDP-1 {
        mode 1920x1080@144Hz
        pos 1920 0
        adaptive_sync off
        max_render_time off
        allow_tearing yes
      }

      # Secondary laptop will ignore eDP-1 config if it has different output name
      # To add secondary laptop config, use: output <name> { ... }

      # Include system config
      include /etc/sway/config.d/*
    '';
  };

  # ===========================================================================
  # WAYBAR (Status Bar)
  # ===========================================================================
  programs.waybar = {
    enable = true;

    settings = {
      mainBar = {
        position = "top";
        spacing = 0;
        height = 0;
        reload_style_on_change = true;
        layer = "top";

        "custom/separator" = {
          format = "::";
          interval = "once";
          tooltip = false;
        };

        modules-left = [
          "sway/workspaces"
          "sway/mode"
        ];

        modules-center = [
          "sway/window"
        ];

        modules-right = [
          "tray"
          "network"
          "custom/separator"
          "cpu"
          "custom/separator"
          "memory"
          "custom/separator"
          "battery"
          "custom/separator"
          "clock"
        ];

        "sway/window" = {
          max-length = 50;
        };

        tray = {
          spacing = 10;
          tooltip = false;
        };

        cpu = {
          format = "cpu {usage}%";
          interval = 2;
          states = {
            critical = 90;
          };
        };

        memory = {
          format = "mem {percentage}%";
          interval = 2;
          states = {
            critical = 80;
          };
        };

        battery = {
          format = "bat {capacity}%";
          interval = 5;
          states = {
            warning = 20;
            critical = 10;
          };
          tooltip = false;
        };

        network = {
          format-wifi = "wifi {bandwidthDownBits}";
          format-ethernet = "enth {bandwidthDownBits}";
          format-disconnected = "no network";
          interval = 5;
          tooltip = false;
        };

        pulseaudio = {
          scroll-step = 5;
          max-volume = 150;
          format = "vol {volume}%";
          format-bluetooth = "vol {volume}%";
          nospacing = 1;
          on-click = "pavucontrol";
          tooltip = false;
        };

        clock = {
          format = "{:%a %d %b  %H:%M}";
        };
      };
    };

    style = ''
      * {
        border: none;
        border-radius: 0;
        min-height: 0;
        font-family: "AporeticSerifMonoNerdFont Regular";
        font-size: 16px;
        padding: 0;
      }

      window#waybar {
        background: #000000;
        color: #ffffff;
      }

      tooltip {
        background-color: #090E13;
      }

      #clock,
      #tray,
      #cpu,
      #memory,
      #battery,
      #network,
      #pulseaudio {
        margin: 2px 2px 0px 0px;
        padding: 2px 8px;
      }

      #workspaces button {
        color: #c5c9c7;
      }


      #workspaces button.focused {
        background-color: #c5c9c7;
        color: #090E13;
      }

      #workspaces button.active {
        background-color: #090E13;
        color: #c5c9c7;
      }

      #battery, #tray, #clock, #cpu, #pulseaudio, #memory, #network {
        /* background-color: none; */
        color: #c5c9c7;
      }
    '';
  };

  # ===========================================================================
  # ALACRITTY (Terminal Emulator)
  # ===========================================================================
  programs.alacritty = {
    enable = true;
    settings = {
      general = {
        live_config_reload = true;
        ipc_socket = true;
      };

      window = {
        dimensions = { columns = 0; lines = 0; };
        position = "None";
        padding = { x = 6; y = 6; };
        dynamic_padding = false;
        decorations = "Full";
        opacity = 1.0;
        blur = false;
        startup_mode = "Maximized";
        title = "Alacritty";
        dynamic_title = true;
        decorations_theme_variant = "None";
        level = "Normal";
      };

      scrolling = {
        history = 10000;
        multiplier = 3;
      };

      font = {
        normal = { family = "AporeticSerifMonoNerdFont"; style = "Regular"; };
        bold = { family = "AporeticSerifMonoNerdFont"; style = "Bold"; };
        italic = { family = "AporeticSerifMonoNerdFont"; style = "Italic"; };
        bold_italic = { family = "AporeticSerifMonoNerdFont"; style = "Bold Italic"; };
        size = 16;
        offset = { x = 0; y = 0; };
        builtin_box_drawing = true;
      };

      colors = {
        primary = {
          background = "#000000";
          foreground = "#b0b0b0";
        };
        cursor = {
          text = "#000000";
          cursor = "#b0b0b0";
        };
        normal = {
          black = "#000000";
          red = "#ff7676";
          green = "#8a9a7b";
          yellow = "#d9ba73";
          blue = "#777777";
          magenta = "#ffffff";
          cyan = "#ffffff";
          white = "#ffffff";
        };
        bright = {
          black = "#000000";
          red = "#ff7676";
          green = "#8a9a7b";
          yellow = "#ffffff";
          blue = "#8ebeec";
          magenta = "#ffffff";
          cyan = "#ffffff";
          white = "#ffffff";
        };
        selection = {
          background = "#002353";
          foreground = "#ffffff";
        };
      };

      bell = {
        animation = "Linear";
        duration = 0;
        color = "#ffffff";
        command = "None";
      };

      selection = {
        semantic_escape_chars = ",│`|:\"' ()[]{}<>\t";
        save_to_clipboard = true;
      };

      cursor = {
        style = { shape = "Block"; blinking = "Off"; };
        vi_mode_style = "None";
        blink_interval = 750;
        blink_timeout = 3;
        unfocused_hollow = true;
        thickness = 0.15;
      };

      terminal = {
        shell = "zsh";
        osc52 = "Disabled";
      };

      mouse = {
        hide_when_typing = true;
      };

      debug = {
        render_timer = false;
        persistent_logging = false;
        log_level = "Warn";
        renderer = "None";
        print_events = false;
        highlight_damage = false;
        prefer_egl = false;
      };

      keyboard.bindings = [
        {
          key = "Return";
          mods = "Shift";
          chars = "\x1b\r";
        }
      ];
    };
  };

  # ===========================================================================
  # HELIX (Text Editor)
  # ===========================================================================
  programs.helix = {
    enable = true;

    settings = {
      theme = "koda";

      editor = {
        scrolloff = 10;
        mouse = false;
        line-number = "relative";
        continue-comments = false;
        auto-completion = true;
        path-completion = true;
        auto-format = true;
        rulers = [ 80 120 ];
        color-modes = true;
        trim-trailing-whitespace = true;
        popup-border = "all";
        auto-pairs = false;

        statusline = {
          left = [ "mode" "spinner" "version-control" "spacer" "diagnostics" ];
          center = [ "file-name" "read-only-indicator" "file-modification-indicator" ];
          right = [ "file-encoding" "file-type" "total-line-numbers" "position" "register" ];
        };

        lsp = {
          enable = true;
          display-messages = true;
          auto-signature-help = true;
          display-inlay-hints = false;
        };

        file-picker = {
          deduplicate-links = false;
        };
      };
    };

    languages = {
      language-server.iwe = {
        command = "iwes";
      };

      language = [{
        name = "markdown";
        language-servers = [ "iwe" ];
        auto-format = true;
        soft-wrap = {
          enable = true;
          wrap-at-text-width = true;
        };
        text-width = 120;
      }];
    };

    themes.koda = {
      # Koda theme - A minimal, mostly monochromatic dark theme
      # Converted from koda.nvim (https://github.com/oskarnurm/koda.nvim)

      attribute = "keyword";
      keyword = "keyword";
      "keyword.directive" = "keyword";
      "keyword.control" = "keyword";
      "keyword.control.return" = "danger";
      "keyword.control.import" = "keyword";
      "keyword.control.conditional" = "keyword";
      "keyword.control.repeat" = "keyword";
      "keyword.control.exception" = "keyword";
      "keyword.function" = "keyword";
      "keyword.operator" = "keyword";
      "keyword.storage" = "keyword";
      "keyword.storage.type" = "keyword";
      "keyword.storage.modifier" = "keyword";
      namespace = "keyword";
      punctuation = "keyword";
      "punctuation.delimiter" = "fg";
      "punctuation.bracket" = "fg";
      "punctuation.special" = "fg";
      operator = "keyword";
      special = "fg";
      "variable.other.member" = "fg";
      variable = "fg";
      "variable.parameter" = "fg";
      "variable.builtin" = "const";
      type = "keyword";
      "type.builtin" = "keyword";
      constructor = "fg";
      function = { fg = "func"; modifiers = [ "bold" ]; };
      "function.builtin" = "func";
      "function.method" = "func";
      "function.macro" = "const";
      tag = "keyword";
      "tag.builtin" = "fg";
      "tag.delimiter" = "keyword";
      "tag.attribute" = "keyword";
      comment = "comment";
      constant = "const";
      "constant.builtin" = "const";
      "constant.character" = "string";
      "constant.character.escape" = "fg";
      string = "string";
      "string.regexp" = "string";
      "string.special" = "fg";
      "string.special.url" = { fg = "fg"; underline = { style = "line"; }; };
      "constant.numeric" = "const";
      label = "keyword";

      "markup.heading" = { fg = "emphasis"; modifiers = [ "bold" ]; };
      "markup.bold" = { modifiers = [ "bold" ]; };
      "markup.italic" = { modifiers = [ "italic" ]; };
      "markup.strikethrough" = { fg = "danger"; modifiers = [ "crossed_out" ]; };
      "markup.link" = { fg = "emphasis"; underline = { style = "line"; }; };
      "markup.link.url" = { fg = "info"; underline = { style = "line"; }; };
      "markup.link.text" = "emphasis";
      "markup.raw" = "const";
      "markup.raw.block" = "const";
      "markup.quote" = "comment";
      "markup.list" = "emphasis";
      "markup.list.checked" = "success";
      "markup.list.unchecked" = "danger";

      "diff.plus" = "success";
      "diff.minus" = "danger";
      "diff.delta" = "warning";

      "ui.background" = { bg = "bg"; };
      "ui.background.separator" = { fg = "comment"; };
      "ui.linenr" = { fg = "comment"; };
      "ui.linenr.selected" = { fg = "emphasis"; modifiers = [ "bold" ]; };
      "ui.statusline" = { fg = "fg"; bg = "bg"; };
      "ui.statusline.inactive" = { fg = "comment"; bg = "bg"; };
      "ui.statusline.normal" = { fg = "bg"; bg = "info"; };
      "ui.statusline.insert" = { fg = "bg"; bg = "green"; };
      "ui.statusline.select" = { fg = "bg"; bg = "warning"; };
      "ui.popup" = { bg = "bg"; };
      "ui.window" = { fg = "border"; };
      "ui.help" = { fg = "fg"; bg = "line"; };
      "ui.text" = { fg = "fg"; };
      "ui.text.focus" = { fg = "emphasis"; };
      "ui.text.inactive" = "comment";
      "ui.text.directory" = { fg = "info"; };
      "ui.virtual" = { fg = "comment"; };
      "ui.virtual.ruler" = { bg = "line"; };
      "ui.virtual.jump-label" = { fg = "highlight"; modifiers = [ "bold" ]; };
      "ui.virtual.indent-guide" = { fg = "line"; };
      "ui.virtual.inlay-hint" = { fg = "comment"; };
      "ui.virtual.whitespace" = { fg = "line"; };
      "ui.virtual.wrap" = { fg = "emphasis"; };

      "ui.selection" = { bg = "line"; };
      "ui.selection.primary" = { bg = "line"; };
      "ui.cursor" = { modifiers = [ "reversed" ]; };
      "ui.cursor.select" = { bg = "highlight"; };
      "ui.cursor.insert" = { bg = "emphasis"; };
      "ui.cursor.primary" = { modifiers = [ "reversed" ]; };
      "ui.cursor.primary.select" = { modifiers = [ "reversed" ]; };
      "ui.cursor.primary.insert" = { modifiers = [ "reversed" ]; };
      "ui.cursor.match" = { fg = "emphasis"; underline = { style = "line"; }; };
      "ui.cursorline.primary" = { bg = "line"; };
      "ui.cursorcolumn.primary" = { bg = "line"; };
      "ui.highlight" = { bg = "line"; };
      "ui.highlight.frameline" = { bg = "line"; };
      "ui.debug" = { fg = "warning"; };
      "ui.debug.breakpoint" = { fg = "danger"; };
      "ui.menu" = { fg = "fg"; bg = "bg"; };
      "ui.menu.selected" = { fg = "bg"; bg = "emphasis"; modifiers = [ "bold" ]; };
      "ui.menu.scroll" = { fg = "fg"; bg = "comment"; };
      "ui.gutter" = { bg = "bg"; };
      "ui.gutter.selected" = { bg = "line"; };

      "ui.bufferline" = { fg = "comment"; bg = "bg"; };
      "ui.bufferline.active" = { fg = "emphasis"; bg = "line"; };
      "ui.bufferline.background" = { bg = "bg"; };

      "diagnostic.hint" = { underline = { color = "info"; style = "curl"; }; };
      "diagnostic.info" = { underline = { color = "fg"; style = "curl"; }; };
      "diagnostic.warning" = { underline = { color = "warning"; style = "curl"; }; };
      "diagnostic.error" = { underline = { color = "danger"; style = "curl"; }; };
      "diagnostic.unnecessary" = { modifiers = [ "dim" ]; };
      "diagnostic.deprecated" = { modifiers = [ "crossed_out" ]; };

      warning = "warning";
      error = "danger";
      info = "info";
      hint = "info";

      palette = {
        bg = "#000000";
        fg = "#b0b0b0";
        dim = "#50585d";
        line = "#272727";
        keyword = "#777777";
        comment = "#50585d";
        border = "#ffffff";
        emphasis = "#ffffff";
        func = "#ffffff";
        string = "#8a9a7b";
        const = "#d9ba73";
        highlight = "#8ebeec";
        info = "#8ebeec";
        success = "#8aa372";
        warning = "#d9ba73";
        danger = "#ff7676";
        green = "#8a9a7b";
        orange = "#f54d27";
        red = "#701516";
        yellow = "#d0bf41";
        pink = "#f2a4db";
        cyan = "#5abfb5";
      };
    };
  };
  # ===========================================================================
  # NOTIFICATIONS (Mako)
  # ===========================================================================
  # Lightweight notification daemon for Wayland
  services.mako = {
    enable = true;

    settings = {
      backgroundColor = "#000000";
      textColor = "#b0b0b0";
      borderColor = "#8ebeec";
      borderRadius = 0;
      borderSize = 2;

      font = "AporeticSerifMonoNerdFont 11";  # System font

      defaultTimeout = 5000;           # Auto-dismiss after 5 seconds
      ignoreTimeout = 0;               # Don't ignore app-requested timeouts

      width = 300;                     # Notification width in pixels
      height = 100;                    # Max notification height
      margin = "10";                   # Margin from screen edge
      padding = "10";                  # Internal padding
      anchor = "top-right";            # Where notifications appear (top-right, bottom-left, etc.)

      icons = 1;
      maxIconSize = 48;

      # groupBy = "app-name";          # Group notifications by application
      # maxVisible = 5;                # Max visible notifications at once
    };

    # ---------------------------------------------------------------------------
    # Urgency-specific styling
    # ---------------------------------------------------------------------------
    extraConfig = ''
      [urgency=low]
      border-color=#50585d
      text-color=#50585d
      default-timeout=3000

      [urgency=normal]
      border-color=#8ebeec
      default-timeout=5000

      [urgency=high]
      border-color=#ff7676
      text-color=#ffffff
      default-timeout=0
    '';
  };

# =============================================================================
# SWAYIDLE (Idle Management)
# =============================================================================
# Idle daemon for Wayland - handles screen locking and DPMS
  services.swayidle = {
    enable = true;
    timeouts = [
      {
        timeout = 300;  # 5 minutes
        command = "${pkgs.swaylock}/bin/swaylock -f";
      }
      {
        timeout = 600;  # 10 minutes
        command = "${pkgs.sway}/bin/swaymsg 'output * dpms off'";
        resumeCommand = "${pkgs.sway}/bin/swaymsg 'output * dpms on'";
      }
    ];
  };

  # ===========================================================================
  # SWAYLOCK (Screen Locker)
  # ===========================================================================
  # Wayland screen locker for Sway
  programs.swaylock = {
    enable = true;

    settings = {
      # -------------------------------------------------------------------------
      # Colors - matching system color scheme
      # -------------------------------------------------------------------------
      color = "000000";                    # Background color (black)

      # Text colors
      text-color = "b0b0b0";               # Default text (light gray)
      text-clear-color = "b0b0b0";         # Text when cleared
      text-caps-lock-color = "d9ba73";     # Text when caps lock is on (yellow warning)
      text-ver-color = "ffffff";           # Text during verification (white)
      text-wrong-color = "ff7676";         # Text when password is wrong (red)

      # Ring (outer circle) colors
      ring-color = "777777";               # Default ring (keyword gray)
      ring-clear-color = "8a9a7b";         # Ring when cleared (green)
      ring-caps-lock-color = "d9ba73";     # Ring when caps lock is on (yellow)
      ring-ver-color = "8ebeec";           # Ring during verification (blue)
      ring-wrong-color = "ff7676";         # Ring when password is wrong (red)

      # Inside (inner circle) colors
      inside-color = "000000";             # Default inside (black)
      inside-clear-color = "000000";       # Inside when cleared
      inside-caps-lock-color = "000000";   # Inside when caps lock is on
      inside-ver-color = "000000";         # Inside during verification
      inside-wrong-color = "000000";       # Inside when password is wrong

      # Key highlight colors
      key-hl-color = "8a9a7b";             # Key press highlight (green)
      bs-hl-color = "ff7676";              # Backspace highlight (red)

      # Separator line (between indicator and text)
      line-color = "000000";               # Separator line color
      line-clear-color = "000000";
      line-caps-lock-color = "000000";
      line-ver-color = "000000";
      line-wrong-color = "000000";

      # -------------------------------------------------------------------------
      # Typography
      # -------------------------------------------------------------------------
      font = "AporeticSerifMonoNerdFont";  # System font
      font-size = 16;                      # Font size for text

      # -------------------------------------------------------------------------
      # Indicator appearance
      # -------------------------------------------------------------------------
      indicator-radius = 100;              # Radius of the indicator circle
      indicator-thickness = 10;            # Thickness of the ring
      indicator-idle-visible = false;      # Hide indicator when idle (no input)
      indicator-caps-lock = true;          # Show indicator when caps lock is on

      # -------------------------------------------------------------------------
      # Behavior
      # -------------------------------------------------------------------------
      show-failed-attempts = true;         # Display number of failed login attempts
      show-keyboard-layout = false;        # Show current keyboard layout
      ignore-empty-password = true;        # Don't validate empty password submissions
      daemonize = false;                   # Don't fork into background

      # -------------------------------------------------------------------------
      # Display
      # -------------------------------------------------------------------------
      scaling = "fill";                    # How to scale images (stretch, fill, fit, center, tile)
      # image = "";                        # Path to background image (optional)
    };
  };

  # ===========================================================================
  # TOFI (Application Launcher)
  # ===========================================================================
  programs.tofi = {
    enable = true;
    settings = {
      width = "100%";
      height = "100%";
      border-width = 0;
      outline-width = 0;
      padding-left = "35%";
      padding-top = "30%";
      result-spacing = 25;
      num-results = 5;
      font = "AporeticSerifMonoNerdFont";
      font-size = 18;
      text-color = "#c5c9c7";
      background-color = "#000A";
      selection-color = "#c4746e";
    };
  };

  # ===========================================================================
  # GIT
  # ===========================================================================
  # WARN: `programs.git` generates config at: ~/.config/git/config
  # Git reads configs in order: /etc/gitconfig -> ~/.gitconfig -> ~/.config/git/config
  # To ensure Home Manager's config is used, remove any existing ~/.gitconfig
  home.activation.removeExistingGitconfig = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    rm -f ${config.home.homeDirectory}/.gitconfig
  '';

  programs.git = {
    enable = true;

    # ---------------------------------------------------------------------------
    # Git LFS (Large File Storage)
    # ---------------------------------------------------------------------------
    # Handles large binary files (images, videos, datasets) efficiently
    # by storing them outside the main repository
    lfs.enable = true;

    settings = {
      user.name = "Ilya Sergeev";
      user.email = "wesunnn2@gmail.com";

      init.defaultBranch = "main";     # Default branch name for new repositories

      pull.rebase = true;              # Rebase local commits on top of pulled changes (cleaner history)
      push.autoSetupRemote = true;     # Auto-create remote branch when pushing new local branches
      push.default = "current";        # Push current branch to remote branch with same name

      merge.conflictStyle = "zdiff3";  # Enhanced conflict markers showing base + both changes
      rebase.autoStash = true;         # Auto-stash/unstash uncommitted changes during rebase
      rebase.autoSquash = true;        # Auto-squash commits marked with 'fixup!' or 'squash!'

      log.date = "iso";                      # Use ISO 8601 format (YYYY-MM-DD HH:MM:SS)
      status.showUntrackedFiles = "all";     # Show individual untracked files, not just dirs

      diff.algorithm = "histogram";    # Better diff algorithm (faster, more readable than myers)
      diff.colorMoved = "default";     # Highlight moved code blocks in different color

      commit.verbose = true;           # Show full diff in commit message editor

      # -------------------------------------------------------------------------
      # GitLab Specific
      # -------------------------------------------------------------------------
      gitlab.host = "gitlab.com";      # TODO: Change when switching to self-hosting

      # -------------------------------------------------------------------------
      # Performance & Optimization
      # -------------------------------------------------------------------------
      fetch.prune = true;              # Auto-remove deleted remote branches on fetch
      fetch.pruneTags = true;          # Also prune deleted remote tags

      # -------------------------------------------------------------------------
      # URL Rewriting
      # -------------------------------------------------------------------------
      # Automatically use SSH instead of HTTPS for your GitHub repositories
      # This enables passwordless authentication with SSH keys
      url = {
        "ssh://git@github.com" = {
          insteadOf = "https://github.com";
        };

        "ssh://git@gitlab.com" = {
          insteadOf = "https://gitlab.com";
        };
      };
    };
  };

  # ---------------------------------------------------------------------------
  # GitHub CLI (gh)
  # ---------------------------------------------------------------------------
  programs.gh = {
    enable = true;

    settings = {
      git_protocol = "ssh";   # Use SSH for git operations (requires SSH key setup)
      prompt = "enabled";     # Show interactive prompts for confirmations
      # editor = "";          # Editor for writing descriptions (defaults to $EDITOR)
      # pager = "";           # Pager for long output (defaults to $PAGER or less)
    };

    # GitHub host configuration
    # Specify which user to use for github.com operations
    hosts = {
      "github.com" = {
        user = "clayedcapo";  # Your GitHub username
        # git_protocol = "ssh";  # Can override global git_protocol per host
      };
    };

    # GitHub extensions (install with: gh extension install <repo>)
    # extensions = [];        # Example: gh extension install dlvhdr/gh-dash
  };

  # ---------------------------------------------------------------------------
  # Delta - Syntax-Highlighting Pager for Git
  # ---------------------------------------------------------------------------
  # Enhanced diff viewer with syntax highlighting, line numbers, and themes
  # Automatically integrated with git diff, show, log, blame, and grep
  programs.delta = {
    enable = true;

    # Automatically configure git to use delta for all diff operations
    # Sets: core.pager, interactive.diffFilter, diff.colorMoved
    enableGitIntegration = true;

    options = {
      diff-so-fancy = true;         # Use diff-so-fancy inspired style
      line-numbers = true;          # Show line numbers in left margin
      true-color = "always";        # Enable 24-bit true color support

      navigate = true;              # Enable file navigation in pager

      side-by-side = true;          # Enable split-screen diff view
      # syntax-theme = "Monokai Extended";  # Syntax highlighting theme

      # File header styling
      file-style = "bold yellow";
      file-decoration-style = "yellow ul";

      # Line change styling
      minus-style = "syntax #330000";       # Removed lines (dark red bg)
      plus-style = "syntax #003300";        # Added lines (dark green bg)
      minus-emph-style = "syntax #660000";  # Emphasized removed text
      plus-emph-style = "syntax #006600";   # Emphasized added text

      whitespace-error-style = "reverse red";  # Highlight trailing whitespace
    };
  };

  # ---------------------------------------------------------------------------
  # GitUI - Terminal UI for Git
  # ---------------------------------------------------------------------------
  # Keybindings: https://github.com/extrawurst/gitui#key-bindings
  programs.gitui = {
    enable = true;
    # theme = "";  # Custom theme file path (optional)
  };

  # ===========================================================================
  # GPG (GNU Privacy Guard)
  # ===========================================================================
  # OpenPGP encryption and signing tool
  # Generates config at: ~/.gnupg/gpg.conf
  programs.gpg = {
    enable = true;

    settings = {
      # -----------------------------------------------------------------------
      # UI & Privacy
      # -----------------------------------------------------------------------
      no-greeting = true;              # Skip copyright notice
      no-emit-version = true;          # Don't include GPG version in output (privacy)
      no-comments = false;             # Keep comment packets
      export-options = "export-minimal";  # Export smallest key (removes old signatures)

      # -----------------------------------------------------------------------
      # Key Display & Verification
      # -----------------------------------------------------------------------
      # Show long key IDs (more secure than short 8-character IDs)
      keyid-format = "0xlong";
      with-fingerprint = true;         # Always show fingerprints

      # Display trust/validity information
      list-options = "show-uid-validity";
      verify-options = "show-uid-validity show-keyserver-urls";

      # -----------------------------------------------------------------------
      # Cryptographic Preferences (what you prefer when negotiating)
      # -----------------------------------------------------------------------
      # These are preferences - negotiated with recipient
      personal-cipher-preferences = "AES256";
      personal-digest-preferences = "SHA512";
      personal-compress-preferences = "ZLIB BZIP2 ZIP Uncompressed";
      default-preference-list = "SHA512 SHA384 SHA256 AES256 TWOFISH BLOWFISH ZLIB BZIP2 ZIP Uncompressed";

      # -----------------------------------------------------------------------
      # Algorithm Enforcement (what you always use)
      # -----------------------------------------------------------------------
      # These settings enforce specific algorithms regardless of preferences
      cipher-algo = "AES256";          # Always use AES256 for encryption
      digest-algo = "SHA512";          # Always use SHA512 for hashing
      cert-digest-algo = "SHA512";     # Use SHA512 when signing keys
      compress-algo = "ZLIB";          # Use ZLIB compression

      # -----------------------------------------------------------------------
      # Security Hardening
      # -----------------------------------------------------------------------
      # Explicitly disable weak/old algorithms
      disable-cipher-algo = "3DES";    # Block 3DES (old, weak)
      weak-digest = "SHA1";            # Warn if SHA1 is used (deprecated)

      # -----------------------------------------------------------------------
      # Symmetric Encryption (S2K) Settings
      # -----------------------------------------------------------------------
      # When encrypting with a passphrase (not a key), use these settings
      s2k-cipher-algo = "AES256";      # Cipher for passphrase encryption
      s2k-digest-algo = "SHA512";      # Digest for passphrase hashing
      s2k-mode = "3";                  # Iterated and salted (most secure mode)
      s2k-count = "65011712";          # ~65M iterations (very high, very secure)

      # -----------------------------------------------------------------------
      # Keyserver
      # -----------------------------------------------------------------------
      # Default keyserver for key operations
      keyserver = "hkps://keys.openpgp.org";
    };
  };

  # ---------------------------------------------------------------------------
  # GPG Agent - Key Caching
  # ---------------------------------------------------------------------------
  # Handles passphrase caching and pinentry for GPG operations
  services.gpg-agent = {
    enable = true;

    # Don't use GPG agent for SSH (we use ssh-agent separately)
    enableSshSupport = false;

    # Pinentry program for passphrase prompts
    # Options: pinentry-curses (CLI), pinentry-gnome3 (GUI/Wayland), pinentry-qt (Qt)
    pinentry.package = pkgs.pinentry-gnome3;  # Works well with Wayland/Sway

    # -------------------------------------------------------------------------
    # Cache Settings
    # -------------------------------------------------------------------------
    # How long to cache passphrases in memory
    defaultCacheTtl = 3600;      # Cache for 1 hour (3600 seconds)
    maxCacheTtl = 7200;          # Maximum 2 hours, even with activity

    # SSH cache settings (only applies if enableSshSupport = true)
    defaultCacheTtlSsh = 3600;
    maxCacheTtlSsh = 7200;
  };

  # ===========================================================================
  # SSH (Secure Shell)
  # ===========================================================================
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    # ---------------------------------------------------------------------------
    # Additional Configuration
    # ---------------------------------------------------------------------------
    extraConfig = ''
      # -----------------------------------------------------------------------
      # Connection Settings
      # -----------------------------------------------------------------------
      Compression yes                                     # Compress data for faster transfers

      # Try authentication methods in this order
      PreferredAuthentications publickey,keyboard-interactive,password

      # Only use identities from ssh-agent or explicitly specified (security)
      IdentitiesOnly yes

      # -----------------------------------------------------------------------
      # Security & Privacy
      # -----------------------------------------------------------------------
      # Ask before connecting to unknown hosts
      StrictHostKeyChecking ask

      # Show ASCII art representation of host key (easier verification)
      VisualHostKey yes

      # Use modern, strong cryptographic algorithms
      Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com
      MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
      KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group18-sha512

      # -----------------------------------------------------------------------
      # Connection Management
      # -----------------------------------------------------------------------
      # Remove stale socket files before creating new ones
      StreamLocalBindUnlink yes

      # Don't send locale environment variables (can cause issues on some servers)
      SendEnv -LC_*

      # -----------------------------------------------------------------------
      # User Experience
      # -----------------------------------------------------------------------
      # Automatically add SSH keys to agent when used
      AddKeysToAgent yes

      # Set terminal type for remote sessions
      SetEnv TERM=xterm-256color
    '';

    # ---------------------------------------------------------------------------
    # Host-Specific Configuration
    # ---------------------------------------------------------------------------
    matchBlocks = {
      # -----------------------------------------------------------------------
      # GitHub
      # -----------------------------------------------------------------------
      "github.com" = {
        # Using SSH over the HTTPS port for GitHub (port 22 is banned by some proxies/firewalls)
        hostname = "ssh.github.com";
        # NOTE: GitHub supports SSH endpoint over port 443
        port = 443;
        user = "git";
        identityFile = "~/.ssh/id_ed25519";
      };

      "gitlab.com" = {
        hostname = "gitlab.com";
        user = "git";
        identityFile = "~/.ssh/id_ed25519";
      };

      # -----------------------------------------------------------------------
      # Wildcard: Default settings for all hosts
      # -----------------------------------------------------------------------
      "*" = {
        # Default identity file for all hosts not matched above
        identityFile = "~/.ssh/id_ed25519";

        # -----------------------------------------------------------------------
        # Connection Multiplexing (Performance)
        # -----------------------------------------------------------------------
        # Reuse existing connections for better performance
        # Multiple SSH sessions to the same host share one TCP connection
        controlMaster = "auto";                              # Auto-create control socket
        controlPath = "~/.ssh/sockets/%r@%h:%p";            # Socket location (%r=user, %h=host, %p=port)
        controlPersist = "10m";                              # Keep connection alive for 10 min after last session

        # -----------------------------------------------------------------------
        # Keep-Alive Settings
        # -----------------------------------------------------------------------
        # Prevent disconnections due to idle timeout
        serverAliveInterval = 60;      # Send keepalive packet every 60 seconds
        serverAliveCountMax = 3;       # Disconnect after 3 failed keepalives (180 sec total)

        # -----------------------------------------------------------------------
        # Connection & Security
        # -----------------------------------------------------------------------
        # Hash hostnames in known_hosts for privacy
        hashKnownHosts = true;

        # TODO: No such option in 25.11, deal later when fine-graining ssh configuration
        # Connection timeout in seconds
        # connectTimeout = 10;

        # Don't forward SSH agent by default (security risk)
        forwardAgent = false;

        # X11 forwarding (disabled by default for security)
        forwardX11 = false;

        # TODO: No such option in 25.11, deal later when fine-graining ssh configuration
        # Request TTY allocation (auto: only allocate when needed)
        # requestTTY = "auto";
      };

      "192.168.*" = {
        # Allow to securely use local SSH agent to authenticate on the remote machine
        # It has the same effect as adding cli option `ssh -A user@host`
        forwardAgent = true;
        identityFile = "~/.ssh/id_ed25519";
      };

      # -----------------------------------------------------------------------
      # Example: Work/Organization GitLab/Bitbucket
      # -----------------------------------------------------------------------
      # "gitlab.company.com" = {
      #   hostname = "gitlab.company.com";
      #   user = "git";
      #   identityFile = "~/.ssh/id_work";
      # };

      # -----------------------------------------------------------------------
      # Example: Match all hosts in a domain
      # -----------------------------------------------------------------------
      # "*.internal.company.com" = {
      #   user = "yourusername";
      #   forwardAgent = true;                  # Forward agent for trusted internal hosts
      #   identityFile = "~/.ssh/id_work";
      #   serverAliveInterval = 30;             # More frequent keepalives for internal network
      # };

      # -----------------------------------------------------------------------
      # Example: Jump/Bastion Host Setup
      # -----------------------------------------------------------------------
      # Connect to internal servers through a jump host
      # "bastion" = {
      #   hostname = "bastion.example.com";
      #   user = "admin";
      #   port = 22;
      # };
      #
      # "internal-*" = {
      #   proxyJump = "bastion";                # SSH through bastion host
      #   user = "admin";
      # };

      # -----------------------------------------------------------------------
      # Example: Local Development VM
      # -----------------------------------------------------------------------
      # "dev-vm" = {
      #   hostname = "127.0.0.1";
      #   user = "dev";
      #   port = 2222;
      #   strictHostKeyChecking = "no";         # Don't verify localhost keys
      #   userKnownHostsFile = "/dev/null";     # Don't save localhost keys
      # };

      # -----------------------------------------------------------------------
      # Example: Port Forwarding
      # -----------------------------------------------------------------------
      # "webapp" = {
      #   hostname = "webapp.example.com";
      #   user = "deploy";
      #   # Forward local 8080 to remote 80
      #   localForward = [
      #     { bind.port = 8080; host.address = "localhost"; host.port = 80; }
      #   ];
      #   # Forward remote 9090 to local 3000
      #   remoteForward = [
      #     { bind.port = 9090; host.address = "localhost"; host.port = 3000; }
      #   ];
      # };
    };
  };

  # Create SSH control sockets directory
  home.file.".ssh/sockets/.keep".text = "";

  # ===========================================================================
  # SSH AGENT
  # ===========================================================================
  # Manages SSH keys in memory, caching passphrases for the session
  # Works with the SSH config's "AddKeysToAgent yes" setting
  services.ssh-agent = {
    enable = true;
    enableBashIntegration = true;  # Auto-export SSH_AUTH_SOCK in bash
    enableZshIntegration = true;   # Auto-export SSH_AUTH_SOCK in zsh
  };

  # ===========================================================================
  # YAZI (File Manager)
  # ===========================================================================
  programs.yazi = {
    enable = true;
    enableZshIntegration = true; # allows yazi to change working directory on exit
    enableBashIntegration = true;
    shellWrapperName = "y";

    settings = {
      mgr = {
        linemod = "size";
        show_hidden = true;
        sort_by = "natural";
        sort_dir_first = false;
        show_symlink = true;
      };
    };

    theme = {
      manager = {
        cwd = { fg = "#ffffff"; };  # Current directory - emphasis
        hovered = { fg = "#000000"; bg = "#b0b0b0"; };  # Selected item
        preview_hovered = { underline = true; };

        find_keyword = { fg = "#d9ba73"; italic = true; };  # Search keyword - const
        find_position = { fg = "#8ebeec"; bg = "reset"; italic = true; };  # Search position - info

        marker_selected = { fg = "#8a9a7b"; bg = "#8a9a7b"; };  # Selected marker - green
        marker_copied = { fg = "#d9ba73"; bg = "#d9ba73"; };  # Copied marker - yellow
        marker_cut = { fg = "#ff7676"; bg = "#ff7676"; };  # Cut marker - danger

        tab_active = { fg = "#000000"; bg = "#b0b0b0"; };  # Active tab
        tab_inactive = { fg = "#50585d"; bg = "#000000"; };  # Inactive tab - comment
        tab_width = 1;

        border_symbol = "│";
        border_style = { fg = "#50585d"; };  # Border - comment
      };

      status = {
        separator_open = "";
        separator_close = "";
        separator_style = { fg = "#50585d"; bg = "#50585d"; };  # comment

        mode_normal = { fg = "#000000"; bg = "#8ebeec"; bold = true; };  # info
        mode_select = { fg = "#000000"; bg = "#d9ba73"; bold = true; };  # warning
        mode_unset = { fg = "#000000"; bg = "#777777"; bold = true; };  # keyword

        progress_label = { fg = "#ffffff"; bold = true; };  # emphasis
        progress_normal = { fg = "#8ebeec"; bg = "#272727"; };  # info/line
        progress_error = { fg = "#ff7676"; bg = "#272727"; };  # danger/line

        permissions_t = { fg = "#8a9a7b"; };  # green
        permissions_r = { fg = "#d9ba73"; };  # const/yellow
        permissions_w = { fg = "#ff7676"; };  # danger
        permissions_x = { fg = "#8ebeec"; };  # info
        permissions_s = { fg = "#50585d"; };  # comment
      };

      input = {
        border = { fg = "#8ebeec"; };  # info
        title = { };
        value = { };
        selected = { reversed = true; };
      };

      select = {
        border = { fg = "#8ebeec"; };  # info
        active = { fg = "#ffffff"; };  # emphasis
        inactive = { };
      };

      tasks = {
        border = { fg = "#8ebeec"; };  # info
        title = { };
        hovered = { underline = true; };
      };

      which = {
        mask = { bg = "#000000"; };  # bg
        cand = { fg = "#8ebeec"; };  # info
        rest = { fg = "#50585d"; };  # comment
        desc = { fg = "#b0b0b0"; };  # fg
        separator = "  ";
        separator_style = { fg = "#50585d"; };  # comment
      };

      help = {
        on = { fg = "#8a9a7b"; };  # green
        run = { fg = "#8ebeec"; };  # info
        desc = { fg = "#b0b0b0"; };  # fg
        hovered = { bg = "#272727"; bold = true; };  # line
        footer = { fg = "#000000"; bg = "#b0b0b0"; };  # fg bg reversed
      };

      filetype = {
        rules = [
          # Media
          { mime = "image/*"; fg = "#8ebeec"; }  # info/blue
          { mime = "video/*"; fg = "#f54d27"; }  # orange
          { mime = "audio/*"; fg = "#d9ba73"; }  # const/yellow

          # Archives
          { mime = "application/zip"; fg = "#ff7676"; }  # danger/red
          { mime = "application/gzip"; fg = "#ff7676"; }
          { mime = "application/x-tar"; fg = "#ff7676"; }
          { mime = "application/x-bzip"; fg = "#ff7676"; }
          { mime = "application/x-bzip2"; fg = "#ff7676"; }
          { mime = "application/x-7z-compressed"; fg = "#ff7676"; }
          { mime = "application/x-rar"; fg = "#ff7676"; }

          # Documents
          { mime = "application/pdf"; fg = "#d9ba73"; }  # const
          { mime = "text/*"; fg = "#8a9a7b"; }  # green

          # Code
          { name = "*.rs"; fg = "#f54d27"; }  # orange
          { name = "*.go"; fg = "#8ebeec"; }  # info
          { name = "*.py"; fg = "#d0bf41"; }  # yellow
          { name = "*.js"; fg = "#d9ba73"; }  # const
          { name = "*.ts"; fg = "#8ebeec"; }  # info
          { name = "*.nix"; fg = "#8ebeec"; }  # info

          # Special files
          { name = "*"; is = "exec"; fg = "#8a9a7b"; }  # green
          { name = "*"; is = "link"; fg = "#5abfb5"; }  # cyan
        ];
      };
    };
  };

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

    iconTheme = {
      name = "Nordzy-Icon";
      package = pkgs.nordzy-icon-theme;
    };

    cursorTheme = {
      name = "Apple Cursor";
      package = pkgs.apple-cursor;
      size = 24;
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
  # QT THEMING
  # ===========================================================================
  qt = {
    enable = true;
    platformTheme.name = "gtk"; # Use GTK theme for Qt apps
    style.name = "adwaita-dark";
  };

  # ===========================================================================
  # XDG CONFIGURATION
  # ===========================================================================
  xdg.configFile."mimeapps.list".force = true;

  xdg.mimeApps = {
    enable = true;
    defaultApplications =
      let
        browser = "vivaldi-stable.desktop";
        editor = "Helix.desktop";
      in
      {
        # Browser
        "text/html" = browser;
        "x-scheme-handler/http" = browser;
        "x-scheme-handler/https" = browser;
        "x-scheme-handler/ftp" = browser;
        "x-scheme-handler/about" = browser;
        "application/json" = browser;
        "application/xml" = browser;
        "application/xhtml+xml" = browser;
        "application/xhtml_xml" = browser;
        "application/rdf+xml" = browser;
        "application/rss+xml" = browser;
        "application/x-extension-htm" = browser;
        "application/x-extension-html" = browser;
        "application/x-extension-shtml" = browser;
        "application/x-extension-xht" = browser;
        "application/x-extension-xhtml" = browser;
        "application/x-wine-extension-ini" = editor;

        "x-scheme-handler/zoommtg" = "Zoom.desktop";

        "x-scheme-handler/tg" = "org.telegram.desktop.desktop";

        # PDF
        "application/pdf" = "org.pwmt.zathura.desktop";

        # Images
        "image/*" = "imv-dir.desktop";
        "image/png" = "imv-dir.desktop";
        "image/jpeg" = "imv-dir.desktop";
        "image/gif" = "imv-dir.desktop";
        "image/webp" = "imv-dir.desktop";

        "video/*" = "vlc.desktop";
        "audio/*" = "vlc.desktop";

        # Text (text/html already defined in Browser section above)
        "text/xml" = browser;
        "text/plain" = editor;

        "x-scheme-handler/unknown" = editor;

        "inode/directory" = "yazi.desktop";
      };
  };

  # Enable relatively new (hence not always supported) specification for a standardized way to
  # launch user's preferred terminal.
  xdg.terminal-exec = {
    enable = true;
    settings = {
      default = [ "Alacritty.desktop" ];
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
  home.stateVersion = "25.11";
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
