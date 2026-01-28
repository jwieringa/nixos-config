{
  description = "claude-code native binary";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        version = "2.1.20";

        platformMap = {
          "x86_64-linux" = "linux-x64";
          "aarch64-linux" = "linux-arm64";
        };

        hashMap = {
          "x86_64-linux" = "sha256-+dNpj1N4pIbbLU7qXID5XCzrQQ+86p/8VwO1qslXTPw=";
          "aarch64-linux" = "sha256-64gBx6SoUBshwjXzZnTxcyjmXnls+KYZazv5ojrhb5k=";
        };

        platform = platformMap.${system} or (throw "Unsupported system: ${system}");
        baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";

      in
      {
        packages = {
          claude-code = pkgs.stdenv.mkDerivation {
            pname = "claude-code";
            inherit version;

            src = pkgs.fetchurl {
              url = "${baseUrl}/${version}/${platform}/claude";
              sha256 = hashMap.${system};
            };

            dontUnpack = true;
            dontBuild = true;
            dontStrip = true;

            nativeBuildInputs = [ pkgs.autoPatchelfHook ];
            buildInputs = [ pkgs.stdenv.cc.cc.lib ];

            installPhase = ''
              mkdir -p $out/bin $out/libexec
              cp $src $out/libexec/claude-bin
              chmod +x $out/libexec/claude-bin

              cat > $out/bin/claude <<EOF
#!/usr/bin/env bash
exec env DISABLE_AUTOUPDATER=1 $out/libexec/claude-bin "\$@"
EOF
              chmod +x $out/bin/claude
            '';
          };

          default = self.packages.${system}.claude-code;
        };

        apps.default = flake-utils.lib.mkApp {
          drv = self.packages.${system}.claude-code;
          name = "claude";
        };
      }
    );
}
