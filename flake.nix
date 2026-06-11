{
  inputs = {
    hyprland.url = "github:hyprwm/Hyprland";

    nix-filter.url = "github:numtide/nix-filter";
  };

  outputs =
    {
      self,
      hyprland,
      nix-filter,
      ...
    }:
    let
      inherit (hyprland.inputs) nixpkgs;
      forHyprlandSystems =
        fn:
        nixpkgs.lib.genAttrs (builtins.attrNames hyprland.packages) (
          system: fn system nixpkgs.legacyPackages.${system}
        );
    in
    {
      packages = forHyprlandSystems (
        system: pkgs:
        let
          hyprlandPackage = hyprland.packages.${system}.hyprland;
          hyprFocusShade = pkgs.gcc14Stdenv.mkDerivation {
            pname = "hypr-focus-shade";
            version = "0.1.0";
            src = nix-filter.lib {
              root = ./.;
              include = [
                "src"
                ./Makefile
              ];
            };

            nativeBuildInputs = with pkgs; [ pkg-config ];
            buildInputs = [ hyprlandPackage.dev ] ++ hyprlandPackage.buildInputs;

            installPhase = ''
              mkdir -p $out/lib
              install ./out/hypr-focus-shade.so $out/lib/libhypr-focus-shade.so
            '';

            meta = with pkgs.lib; {
              homepage = "https://github.com/Praczet/hypr-focus-shade";
              description = "Focus-aware per-window shader effects for Hyprland";
              license = licenses.mit;
              platforms = platforms.linux;
            };
          };
        in
        {
          "hypr-focus-shade" = hyprFocusShade;
          default = hyprFocusShade;
        }
      );

      devShells = forHyprlandSystems (
        system: pkgs: {
          default = pkgs.mkShell {
            name = "hypr-focus-shade";
            hardeningDisable = [ "fortify" ];

            nativeBuildInputs = with pkgs; [
              clang-tools
              jq
              chromium
            ];

            inputsFrom = [ self.packages.${system}."hypr-focus-shade" ];
          };
        }
      );
    };
}
