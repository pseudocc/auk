{
  description = "🌊🐦";

  # zig 0.14.0
  inputs.nixpkgs.url = "github:nixos/nixpkgs";

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    inherit (nixpkgs) lib;

    eachSystem = fn:
      lib.foldl' (
        acc: system:
          lib.recursiveUpdate
          acc
          (lib.mapAttrs (_: value: {${system} = value;}) (fn system))
      ) {}
      lib.platforms.unix;

    version = with builtins; let
      matched_group = match ''.+\.version = "([^"]+)",.+'' (readFile ./build.zig.zon);
    in elemAt matched_group 0;
  in
    eachSystem (
      system: let
        pkgs = import nixpkgs {inherit system;};
        zig = pkgs.zig_0_14;
        zls = pkgs.zls;

        mkauk = optimize: pkgs.stdenv.mkDerivation {
          inherit version;
          pname = "auk";

          buildInputs = [ zig.hook ];
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

          zigBuildFlags = [ "-Doptimize=${optimize}" ];
          passthru = { inherit optimize zig; };

          meta = {
            description = "AUK";
            license = lib.licenses.free;
            mainProgram = "auk";
          };
        };
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = [ zig zls ];
        };

        apps = let
          ctor.auk = name: pkg: {
            inherit name;
            value = {
              type = "app";
              program = lib.getExe pkg;
            };
          };
          entries = lib.mapAttrsToList ctor.auk rec {
            auk-debug = mkauk "Debug";
            auk-release-fast = mkauk "ReleaseFast";
            auk-release-safe = mkauk "ReleaseSafe";
            auk = auk-release-fast;
            default = auk;
          };
        in builtins.listToAttrs entries;
      }
    );
}
