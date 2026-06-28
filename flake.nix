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
            builtins.elem (nixpkgs.lib.getName pkg) [ "claude-code" "terraform" ];
        }));
    in {
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            # shared tooling
            claude-code
            git
            gh
            jq
            # worker dev (infra/scheduler): TypeScript build via npm/tsc.
            # (wrangler isn't pinned here — its nixpkgs source build is flaky;
            #  run it on demand with `npx wrangler ...` for local tail/dev.)
            nodejs_22 # bundles npm + npx; matches CI's node 22
            # infra deploy (infra/terraform)
            terraform
          ];

          shellHook = ''
            echo "autopilot dev shell"
            echo "  claude    $(claude --version 2>/dev/null || echo '(run: claude setup-token)')"
            echo "  gh        $(gh --version | head -1)"
            echo "  node/npm  $(node --version 2>/dev/null) / npm $(npm --version 2>/dev/null)"
            echo "  tf        $(terraform version 2>/dev/null | head -1)"
          '';
        };
      });
    };
}
