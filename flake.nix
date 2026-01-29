{
  description = "NixOS with Home Manager configuration for both laptops";

  # ===========================================================================
  # BINARY CACHES
  # ===========================================================================
  # This will add additional third-party caches
  # WARN: This could be a security concern, because:
  #  1) We should trust added cache (by trusting cache's public key)
  #  2) Current user should be a trusted user to utilize them
  # NOTE: Flake method changes caches only for evaluation of flake (there's
  # also system-wide and command line variants)
  nixConfig = {
    # NOTE: Consider to use close-located mirror instead of official
    # `extra-` for adding substituters to default ones, not replacing them
    extra-substituters = [
      # "https://nix-community.cachix.org"
      # "https://nix-gaming.cachix.org"
      # "https://install.determinate.systems"
      # "https://nixpkgs-wayland.cachix.org"
    ];

    extra-trusted-public-keys = [
      # "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      # "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
      # "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
      # "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
    ];
  };

  # ===========================================================================
  # INPUTS
  # ===========================================================================
  inputs = {
    # -------------------------------------------------------------------------
    # Core: Nixpkgs
    # -------------------------------------------------------------------------
    # NOTE: 24.11 stable as default, change to unstable in the future maybe
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # -------------------------------------------------------------------------
    # Core: Home Manager
    # -------------------------------------------------------------------------
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # -------------------------------------------------------------------------
    # Core: Disko (declarative disk partitioning)
    # -------------------------------------------------------------------------
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # -------------------------------------------------------------------------
    # Optional: NUR (Nix User Repository)
    # -------------------------------------------------------------------------
    nur.url = "github:nix-community/NUR";

    # -------------------------------------------------------------------------
    # Optional: Custom packages
    # -------------------------------------------------------------------------
    aporetic-nerd-font = {
      url = "github:Echinoidea/Aporetic-Nerd-Font";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    #
    # OPTIONAL: Add more inputs as needed
    # Examples:
    # - stylix for system-wide theming
    # - nix-colors for color scheme management
  };

  # ===========================================================================
  # OUTPUTS
  # ===========================================================================
  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, disko, nur, ... }@inputs:
    let
      system = "x86_64-linux";
      username = "clayedcapo";

      # -----------------------------------------------------------------------
      # Package Sets
      # -----------------------------------------------------------------------
      # NOTE: Probably don't need this one `nixosSystem` produces pkgs by itself
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

      # -----------------------------------------------------------------------
      # Helper: System Builder
      # -----------------------------------------------------------------------
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
          # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
          # Trusted Users
          # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
          # Give the users in this list the right to specify additional substituters via
          # `nixConfig.substituters` in `flake.nix`
          {
            nix.settings.trusted-users = [ "${username}" ];
          }

          # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
          # Shared Configuration
          # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
          ./configuration.nix

          # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
          # Disko: Declarative Disk Partitioning
          # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
          disko.nixosModules.disko
          ./disko.nix

          # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
          # Home Manager: User Environment Management
          # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
          # This integrates Home Manager into system configuration
          # Alternative: standalone Home Manager (see commented section below)
          home-manager.nixosModules.home-manager
          {
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
          }
          #
          # STANDALONE HOME MANAGER (OPTIONAL)
          # ==================================
          # Use this if you want to manage home-manager separately from NixOS
          # This is useful for:
          # - Managing dotfiles on non-NixOS systems
          # - Testing home configs without rebuilding the whole system
          #
          # Comment out the home-manager integration above if using this
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

    # =========================================================================
    # SYSTEM CONFIGURATIONS
    # =========================================================================
    in {
      nixosConfigurations = {

        # Main laptop: AMD CPU + NVIDIA GPU (16GB RAM)
        main = mkSystem "main" [
          ./hosts/main/default.nix
          ./hosts/main/amd-nvidia.nix
        ];

        # Secondary laptop: Intel CPU + AMD GPU (4GB RAM)
        secondary = mkSystem "secondary" [
          ./hosts/secondary/default.nix
          ./hosts/secondary/intel-amd.nix
        ];

      };
    };
}
# =============================================================================
# USAGE GUIDE
# =============================================================================
#
# BUILD AND SWITCH
# ----------------
#   sudo nixos-rebuild switch --flake .#main       # For main laptop
#   sudo nixos-rebuild switch --flake .#secondary  # For secondary laptop
#
# UPDATE DEPENDENCIES
# -------------------
#   sudo nix flake update              # Update all inputs
#   sudo nix flake update nixpkgs      # Update only nixpkgs
#
# ROLLBACK
# --------
#   sudo nixos-rebuild switch --flake .#<main or secondary> --rollback
#   # Or select previous generation from bootloader
#
# =============================================================================
# FLAKE.LOCK FILE
# =============================================================================
#
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
# =============================================================================
# DIRECTORY STRUCTURE
# =============================================================================
#
# .
# ├── flake.nix              # This file - main entry point
# ├── flake.lock             # Generated - locks dependency versions
# ├── configuration.nix      # Shared system configuration
# ├── disko.nix              # Disk layout
# ├── home.nix               # Home Manager configuration
# └── hosts/
#     ├── main/
#     │   ├── default.nix              # Host-specific settings
#     │   ├── amd-nvidia.nix           # GPU configuration
#     │   └── hardware-configuration.nix
#     └── secondary/
#         ├── default.nix
#         ├── intel-amd.nix
#         └── hardware-configuration.nix

