{
  description = "autopilot — life-automation batches";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "aarch64-darwin" "x86_64-darwin" "aarch64-linux" "x86_64-linux" ];
      forAllSystems = f:
        nixpkgs.lib.genAttrs systems (system: f (import nixpkgs {
          inherit system;
          config.allowUnfreePredicate = pkg:
            builtins.elem (nixpkgs.lib.getName pkg) [ "claude-code" ];
        }));
    in {
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            claude-code
            git
            gh
            jq
          ];

          shellHook = ''
            echo "autopilot dev shell"
            echo "  claude  $(claude --version 2>/dev/null || echo '(run: claude setup-token)')"
            echo "  gh      $(gh --version | head -1)"
          '';
        };
      });
    };
}
