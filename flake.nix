{
  description = "NixOS with Home Manager configuration for both laptops";

  # This will add additional third-party caches.
  # WARN: This could be a security concern, because:
  #  1) We should trust added cache (by trusting cache's public key).
  #  2) Current user should be a trusted user to utilize them.
  # NOTE: Flake method changes caches only for evaluation of flake (there's
  # also system-wide and command line variants).
  nixConfig = {
    # Consider to use close-located mirror instead of official
    # `extra-` for adding substituters to default ones, not replacing them
    extra-substituters = [
      # Cache for NUR
      "https://nix-community.cachix.org"
      # "https://nix-gaming.cachix.org"
    ];

    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      # "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
    ];
  };

  inputs = {
    # 24.11 stable as default, change to unstable in the future maybe
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    nur.url = "github:nix-community/NUR";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    aporetic-nerd-font = {
      url = "github:Echinoidea/Aporetic-Nerd-Font";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # OPTIONAL: Add more inputs as needed
    # Examples:
    # - stylix for system-wide theming
    # - nix-colors for color scheme management
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, disko, nur, ... }@inputs:
    let
      system = "x86_64-linux";
      username = "clayedcapo";

      # pkgs = import nixpkgs {
      #   inherit system;
      #   config = {
      #     allowUnfree = true;  # Allow proprietary packages (NVIDIA drivers, etc.)
      #   };
      # };

      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config = {
          allowUnfree = true;
        };
      };

      # Helper function for specifying multiple systems
      mkSystem = hostname: modules: nixpkgs.lib.nixosSystem {
        inherit system;

        # Additional custom inputs to all sub-modules
        specialArgs = {
          inherit inputs;
          inherit pkgs-unstable;
          inherit username;
          inherit hostname;
        };

        modules = [
          {
            # Give the users in this list the right to specify additional substituters via
            # `nixConfig.substituters` in `flake.nix`.
            nix.settings.trusted-users = [ "${username}" ];
          };

          ./configuration.nix

          disko.nixosModules.disko
          ./disko.nix

          # Home Manager as a NixOS module
          # This integrates Home Manager into system configuration
          # Alternative: standalone Home Manager
          home-manager.nixosModules.home-manager
          {
            # Home Manager configuration
            home-manager = {
              useGlobalPkgs = true;      # Use system's pkgs (don't create separate)
              useUserPackages = true;    # Install user packages to /etc/profiles instead of ~/.nix-profile

              # Pass extra arguments to Home Manager modules
              extraSpecialArgs = {
                inherit inputs;
                inherit pkgs-unstable;
                inherit username;
                inherit hostname;
              };

              # User configurations
              users.${username} = import ./home.nix;
            };
          };

          # STANDALONE HOME MANAGER CONFIGURATIONS (OPTIONAL)
          # ==================================================
          # Use this if you want to manage home-manager separately from NixOS
          # This is useful for:
          # - Managing dotfiles on non-NixOS systems
          # - Testing home configs without rebuilding the whole system
          #
          # Comment out the home-manager integration in nixosConfigurations above if using this
          # homeConfigurations = {
          #   "${username}" = home-manager.lib.homeManagerConfiguration {
          #     inherit pkgs;
          #     extraSpecialArgs = {
          #       inherit inputs pkgs-unstable username;
          #     };
          #     modules = [ ./home.nix ];
          #   };
          # };
        ] ++ modules;
      };

      # stateVersion = "24.11"; # DON'T CHANGE after installation
    in {
      nixosConfigurations = {

        main = mkSystem "main" [
          ./hosts/main/default.nix
          ./hosts/main/amd-nvidia.nix
        ];

        secondary = mkSystem "secondary" [
          ./hosts/secondary/default.nix
          ./hosts/secondary/intel-amd.nix
        ];

        # OPTIONAL: Additional system configurations
        # Example for a second machine:
        # laptop = nixpkgs.lib.nixosSystem {
        #   system = "x86_64-linux";
        #   specialArgs = { inherit inputs pkgs-unstable; };
        #   modules = [ ./laptop-configuration.nix ];
        # };
      };

    };
}

# HOW TO USE THIS FLAKE
# =====================
#
# 1. Initial Setup:
#    cd /etc/nixos
#    sudo vim flake.nix  # Create this file
#    sudo nix flake update  # Generate flake.lock
#
# 2. Build and switch:
#    sudo nixos-rebuild switch --flake .#<main or secondary>
#    # The ".#<main or secondary>" means:
#    #   . = current directory (where flake.nix is)
#    #   #<main or secondary> = the configuration name from nixosConfigurations
#
# 3. Update dependencies:
#    sudo nix flake update  # Updates all inputs to latest versions
#    sudo nix flake update nixpkgs  # Update only nixpkgs
#    sudo nixos-rebuild switch --flake .#<main or secondary>
#
# 4. Rollback if something breaks:
#    sudo nixos-rebuild switch --flake .#<main or secondary> --rollback
#    # Or just reboot and select previous generation from bootloader
#
# FLAKE.LOCK FILE
# ===============
# After running "nix flake update", a flake.lock file is created.
# This file locks the EXACT commits of all your inputs.
#
# Why this matters:
# - Two people with the same flake.nix and flake.lock get IDENTICAL systems
# - You can reproduce your exact system even years later
# - You explicitly control when dependencies update (no surprise updates)
#
# Commit both flake.nix and flake.lock to git!
#
# DIRECTORY STRUCTURE WITH FLAKES
# ================================
# /etc/nixos/
# ├── flake.nix                    # This file - main entry point
# ├── flake.lock                   # Generated - locks dependency versions
# ├── configuration.nix            # System configuration
# ├── hardware-configuration.nix   # Hardware-specific settings
# ├── disko-config.nix            # Disk layout
# ├── home.nix                    # Home Manager configuration
# └── modules/                    # Optional: additional modules
#     ├── nvidia.nix
#     └── gaming.nix
#
# ADVANTAGES OF FLAKES
# =====================
# 1. Reproducibility: Exact versions locked in flake.lock
# 2. Composability: Easy to import others' configurations
# 3. Speed: Flakes are evaluated more efficiently
# 4. Standards: Everyone's flakes have similar structure
# 5. No channels: Dependencies explicit, not global system state
#
# DISADVANTAGES / GOTCHAS
# ========================
# 1. Still "experimental" (but widely used and stable in practice)
# 2. Requires enabling: nix.settings.experimental-features = [ "nix-command" "flakes" ];
# 3. Different commands: nixos-rebuild switch --flake instead of just nixos-rebuild switch
# 4. Git requirement: Flakes work best in git repos (uses git to track files)
#
# MIGRATION FROM CHANNELS
# =======================
# Old way (channels):
#   sudo nix-channel --list
#   sudo nix-channel --update
#   sudo nixos-rebuild switch
#
# New way (flakes):
#   cat /etc/nixos/flake.lock  # See what versions you have
#   sudo nix flake update
#   sudo nixos-rebuild switch --flake /etc/nixos#<main or secondary>
#
# The flake inputs replace channels entirely.

