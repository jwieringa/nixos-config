{
  description = "Ruby on Rails development environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs-ruby.url = "github:bobvanderlinden/nixpkgs-ruby";
  };

  outputs = { self, nixpkgs, nixpkgs-ruby, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      ruby = nixpkgs-ruby.packages.${system}."ruby-3.1.7";
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
	    pkgs.libyaml
            pkgs.yarn

            # The libgeos-dev package on NixOS
            # https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/libraries/geos/default.nix
            pkgs.geos

            # for mysql gem building
	    pkgs.mysql84

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
       
       # MySQL setup
       export MYSQL_HOME=$HOME/mysql
       export MYSQL_DATADIR=$MYSQL_HOME/data
       export MYSQL_UNIX_PORT=$MYSQL_HOME/mysql.sock
       export MYSQL_LOG=$MYSQL_HOME/mysql.log
       
       mkdir -p $MYSQL_HOME
       
       if [ ! -d $MYSQL_DATADIR ]; then
         echo "Initializing MySQL database..."
         mysqld --initialize-insecure --datadir=$MYSQL_DATADIR
       fi
       
       # Check if MySQL is already running
       if ! pgrep -f "mysqld.*$MYSQL_DATADIR" > /dev/null; then
         echo "Starting MySQL server..."
         mysqld --datadir=$MYSQL_DATADIR --socket=$MYSQL_UNIX_PORT --pid-file=$MYSQL_HOME/mysql.pid --log-error=$MYSQL_LOG &
         
         # Wait a moment for MySQL to start
         sleep 2
         
         if pgrep -f "mysqld.*$MYSQL_DATADIR" > /dev/null; then
           echo "MySQL server started successfully."
           echo "Default credentials: User 'root' with no password."
           echo "Connect using: mysql -u root -S $MYSQL_UNIX_PORT"
         else
           echo "WARNING: MySQL server failed to start. Check $MYSQL_LOG for details."
         fi
       else
         echo "MySQL server is already running."
       fi
       
       # Redis setup
       export REDIS_HOME=$HOME/redis
       export REDIS_PORT=6379
       export REDIS_URL="redis://localhost:$REDIS_PORT"
       
       mkdir -p $REDIS_HOME
       
       # Check if Redis is already running
       if ! pgrep -f "redis-server.*$REDIS_PORT" > /dev/null; then
         echo "Starting Redis server..."
         redis-server --daemonize yes --port $REDIS_PORT --dir $REDIS_HOME --pidfile $REDIS_HOME/redis.pid --logfile $REDIS_HOME/redis.log
         
         if pgrep -f "redis-server.*$REDIS_PORT" > /dev/null; then
           echo "Redis server started successfully."
           echo "Redis URL: $REDIS_URL"
         else
           echo "WARNING: Redis server failed to start."
         fi
       else
         echo "Redis server is already running."
       fi
     
       # Make sure shellHook exits properly
       true  # Ensure the last command returns success
     '';
        };
      };
    });
}
