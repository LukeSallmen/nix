{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-23.05";
      inputs.nixpkgs.follows = "nixpkgs";
  };
    hyprland.url = "github:hyprwm/Hyprland";

  };
  outputs = { self, nixpkgs, home-manager, hyprland, ... }: 
    let 
     system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      lib = nixpkgs.lib;
    in{
      nixosConfigurations = {
        lukes = lib.nixosSystem {
          inherit system;
          modules = [ 
            ./configuration.nix
            # this allows me to use sudo nixos-rebuild switch --flake .#lukes
            # in order to rebuild home manager and nixos
            home-manager.nixosModules.home-manager {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              # home-manager.users.lukes = {
              #   imports = [ ./home.nix];
              # };
            }
            ];
        };
      };
      hmConfig = {
        lukes = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          modules = [
            # ./home.nix
            # ./some-extra-module.nix
            hyprland.homeManagerModules.default
            {wayland.windowManager.hyprland.enable = true;}
            {
              home = {
                programs.home-manager.enable = true;
                home.stateVersion = "23.05";
                username = "lukes";
                homeDirectory = "/home/lukes";
                stateVersion = "23.05";
                wayland.windowManager.hyprland.extraConfig = ''
                  $mod = SUPER

                  bind = $mod, F, exec, firefox
                  bind = , Print, exec, grimblast copy area

                  # workspaces
                  # binds $mod + [shift +] {1..10} to [move to] workspace {1..10}
                  ${builtins.concatStringsSep "\n" (builtins.genList (
                      x: let
                        ws = let
                          c = (x + 1) / 10;
                        in
                          builtins.toString (x + 1 - (c * 10));
                      in ''
                        bind = $mod, ${ws}, workspace, ${toString (x + 1)}
                        bind = $mod SHIFT, ${ws}, movetoworkspace, ${toString (x + 1)}
                      ''
                    )
                    10)}

                  # ...
                '';
              };
            }
          ];
        };
      };
    };
  
}