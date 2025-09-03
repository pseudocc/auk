{
  description = "🌊🐦";

  inputs.nixpkgs.url = "github:pseudocc/nixpkgs/zig-0.15.1";

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
        zig = pkgs.zig;
        zls = pkgs.zls;

        mkauk = optimize: pkgs.stdenv.mkDerivation {
          inherit version;
          pname = "auk";

          buildInputs = [
            (zig.hook.overrideAttrs {
              zig_default_flags = [
                "-Dcpu=baseline"
                "--release=${optimize}"
                "--color off"
              ];
            })
          ];

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
            auk-debug = mkauk "off";
            auk-release-fast = mkauk "fast";
            auk-release-safe = mkauk "safe";
            auk-release-small = mkauk "small";
            auk = auk-release-fast;
            default = auk;
          };
        in builtins.listToAttrs entries;
      }
    );
}
