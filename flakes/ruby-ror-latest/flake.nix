{
  description = "Ruby on Rails (latest) development environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-ruby.url = "github:bobvanderlinden/nixpkgs-ruby";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-ruby,
    }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          ruby = nixpkgs-ruby.packages.${system}."ruby-3.4.3";
        in
        rec {
          default = run;

          run = pkgs.mkShell {
            buildInputs = [
              ruby
              pkgs.postgresql_16
              pkgs.nodejs
              pkgs.redis
              pkgs.libyaml
              pkgs.yarn
            ];

            shellHook = ''
              # PostgreSQL setup
              export PGHOST=$HOME/postgres
              export PGDATA=$PGHOST/data
              export PGDATABASE=postgres
              export PGLOG=$PGHOST/postgres.log

              mkdir -p $PGHOST

              if [ ! -d $PGDATA ]; then
                initdb --auth=trust --no-locale --encoding=UTF8
              fi

              # Check if PostgreSQL is already running
              if ! pg_ctl status > /dev/null 2>&1; then
                echo "Starting PostgreSQL server..."
                # Start PostgreSQL detached with -w flag to wait until startup is complete
                pg_ctl start -D $PGDATA -l $PGLOG -o "--unix_socket_directories='$PGHOST'" -w > /dev/null 2>&1

                if pg_ctl status > /dev/null 2>&1; then
                  echo "PostgreSQL server started successfully."
                else
                  echo "WARNING: PostgreSQL server failed to start. Check $PGLOG for details."
                fi
              else
                echo "PostgreSQL server is already running."
              fi

              # Make sure shellHook exits properly
              true  # Ensure the last command returns success
            '';
          };
        }
      );
    };
}
