{
  description = "🌊🐦";

  inputs.nixpkgs.url = "github:pseudocc/nixpkgs/zig-0.15.1";

  outputs = { self, nixpkgs }: import ./nix/each-system.nix nixpkgs (
    system: pkgs: let
      inherit (pkgs) lib;
      name = "auk";
      version = import ./nix/version.nix ./build.zig.zon;
      mkDrv = optimize: pkgs.stdenv.mkDerivation {
        inherit version;
        pname = name;
        src = with lib.fileset; toSource {
          root = ./.;
          fileset = unions [
            ./core
            ./terminal
            ./manifest.zig
            ./auk.zig
            ./build.zig
            ./build.zig.zon
            ./LICENSE
          ];
        };

        buildInputs = [
          (pkgs.zig.hook.overrideAttrs {
            zig_default_flags = [
              "-Dcpu=baseline"
              "--release=${optimize}"
              "--color off"
            ];
          })
        ];

        outputs = [ "out" "doc" ];
        postInstall = ''
          install -D -m644 LICENSE $doc/share/doc/LICENSE
        '';

        meta = {
          description = "AUK event monitor";
          license = lib.licenses.free;
          mainProgram = name;
        };
      };
    in {
      devShells.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          zig
          zls
        ];
      };

      packages = {
        "${name}-debug" = mkDrv "off";
        "${name}-release-fast" = mkDrv "fast";
        "${name}-release-small" = mkDrv "small";
        "${name}-release-safe" = mkDrv "safe";
        ${name} = mkDrv "safe";
        default = mkDrv "safe";
      };

      apps = let
        mkApp = name: drv: {
          type = "app";
          program = lib.getExe drv;
        };
      in
        lib.mapAttrs mkApp self.packages.${system};
    }
  );
}
