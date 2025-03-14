{
  description = "Ruby on Rails development environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs-ruby.url = "github:bobvanderlinden/nixpkgs-ruby";
    nixpkgs-ruby.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nixpkgs-ruby, flake-utils }:
  flake-utils.lib.eachDefaultSystem (system:
  let
    pkgs = nixpkgs.legacyPackages.${system};
    cwd = builtins.getEnv "PWD";
    rubyVersion = nixpkgs.lib.strings.trim (builtins.readFile "${cwd}/.ruby-version");
    ruby = nixpkgs-ruby.packages.${system}."ruby-${rubyVersion}";
  in
  {
    devShells = rec {
      default = run;

      run = pkgs.mkShell {
        buildInputs = [
          ruby
          pkgs.postgresql_16
          pkgs.nodejs
          pkgs.proj
          pkgs.redis
          pkgs.yarn

          # The libgeos-dev package on NixOS
          # https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/libraries/geos/default.nix
          pkgs.geos

          pkgs.docker-compose

          # For Parquet
          pkgs.libffi
          pkgs.libffi.dev
          pkgs.glib
          pkgs.glib.dev
          pkgs.pkg-config
        ];

   shellHook = ''
     # RGEO paths for bundle install
     # Manual steps
     #
     # find /nix/store -name "libgeos_c.so" | head -n 1
     # GEOS_LIBRARY_PATH=/nix/store/some-hash-geos-3.x.x/lib bundle install
     export GEOS_LIBRARY_PATH=${pkgs.geos}/lib
     export GEOS_INCLUDE_PATH=${pkgs.geos}/include

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
    };
  });
}
