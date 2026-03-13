{
  description = "A tiny fzf launcher for directory-local .lawnrc manifests";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      forAllSystems = f:
        nixpkgs.lib.genAttrs systems (system: f system (import nixpkgs { inherit system; }));
    in
    {
      packages = forAllSystems (system: pkgs:
        let
          lawn = pkgs.writeShellApplication {
            name = "lawn.sh";
            runtimeInputs = [
              pkgs.coreutils
              pkgs.fd
              pkgs.fzf
              pkgs.gnused
            ];
            meta = {
              description = "A tiny fzf launcher for directory-local .lawnrc manifests";
              mainProgram = "lawn.sh";
              platforms = pkgs.lib.platforms.unix;
            };
            text = builtins.readFile ./lawn.sh;
          };
        in
        {
          default = lawn;
        });

      apps = forAllSystems (system: pkgs: {
        default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/lawn.sh";
          meta = {
            description = "A tiny fzf launcher for directory-local .lawnrc manifests";
          };
        };
      });

      checks = forAllSystems (system: pkgs: {
        default = pkgs.runCommand "lawn-check" {
          nativeBuildInputs = [
            pkgs.bash
            pkgs.coreutils
            pkgs.gnugrep
          ];
        } ''
          bash ${./tests/check.bash} ${self.packages.${system}.default}/bin/lawn.sh
          touch "$out"
        '';
      });
    };
}
