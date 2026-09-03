# Dev-shell layers, each a small mkShell owning one concern. Project shells
# compose them with `inputsFrom` (see default.nix).
#
# Conventions:
# - Anything a gem extension links against goes in buildInputs (libpq,
#   libmysqlclient, GEOS, ImageMagick, ...); tools go in packages.
# - Service hooks are idempotent because every worktree shares
#   $HOME/postgres, $HOME/redis and $HOME/mysql: they only start a server
#   when none is running.
# - Every hook ends with `true` so the concatenated shellHook never leaves
#   direnv a non-zero exit status.
{ pkgs }:
{
  # libyaml and libffi back psych and ffi, which nearly every Gemfile pulls
  # in; pkg-config's setup hook exposes every library layer's .pc files.
  ruby =
    ruby:
    pkgs.mkShell {
      name = "ruby-${ruby.version}";
      buildInputs = [
        ruby
        pkgs.libyaml
        pkgs.libffi
        pkgs.libffi.dev
      ];
      packages = [ pkgs.pkg-config ];
    };

  postgres = pkgs.mkShell {
    name = "postgres";
    buildInputs = [ pkgs.postgresql_16 ];
    shellHook = ''
      export PGHOST=$HOME/postgres
      export PGDATA=$PGHOST/data
      export PGDATABASE=postgres
      export PGLOG=$PGHOST/postgres.log

      mkdir -p $PGHOST

      if [ ! -d $PGDATA ]; then
        initdb --auth=trust --no-locale --encoding=UTF8
      fi

      if ! pg_ctl status > /dev/null 2>&1; then
        echo "Starting PostgreSQL server..."
        # -w waits until the server accepts connections.
        pg_ctl start -D $PGDATA -l $PGLOG -o "--unix_socket_directories='$PGHOST'" -w > /dev/null 2>&1

        if pg_ctl status > /dev/null 2>&1; then
          echo "PostgreSQL server started successfully."
        else
          echo "WARNING: PostgreSQL server failed to start. Check $PGLOG for details."
        fi
      else
        echo "PostgreSQL server is already running."
      fi

      true
    '';
  };

  redis = pkgs.mkShell {
    name = "redis";
    packages = [ pkgs.redis ];
    shellHook = ''
      export REDIS_HOME=$HOME/redis
      export REDIS_DATA=$REDIS_HOME/data
      export REDIS_LOG=$REDIS_HOME/redis.log
      export REDIS_PID=$REDIS_HOME/redis.pid
      export REDIS_PORT=6379
      export REDIS_URL="redis://localhost:$REDIS_PORT"

      mkdir -p $REDIS_HOME $REDIS_DATA

      if ! redis-cli ping > /dev/null 2>&1; then
        echo "Starting Redis server..."
        redis-server --daemonize yes \
          --dir $REDIS_DATA \
          --logfile $REDIS_LOG \
          --pidfile $REDIS_PID \
          --port $REDIS_PORT > /dev/null 2>&1

        sleep 1

        if redis-cli ping > /dev/null 2>&1; then
          echo "Redis server started successfully on port $REDIS_PORT."
        else
          echo "WARNING: Redis server failed to start. Check $REDIS_LOG for details."
        fi
      else
        echo "Redis server is already running."
      fi

      true
    '';
  };

  # The mysql2 gem links against libmysqlclient from this package.
  mysql = pkgs.mkShell {
    name = "mysql";
    buildInputs = [ pkgs.mysql84 ];
    shellHook = ''
      export MYSQL_HOME=$HOME/mysql
      export MYSQL_DATADIR=$MYSQL_HOME/data
      export MYSQL_UNIX_PORT=$MYSQL_HOME/mysql.sock
      export MYSQL_LOG=$MYSQL_HOME/mysql.log

      mkdir -p $MYSQL_HOME

      if [ ! -d $MYSQL_DATADIR ]; then
        echo "Initializing MySQL database..."
        mysqld --initialize-insecure --datadir=$MYSQL_DATADIR
      fi

      if ! pgrep -f "mysqld.*$MYSQL_DATADIR" > /dev/null; then
        echo "Starting MySQL server..."
        mysqld --datadir=$MYSQL_DATADIR --socket=$MYSQL_UNIX_PORT --pid-file=$MYSQL_HOME/mysql.pid --log-error=$MYSQL_LOG &

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

      true
    '';
  };

  # rgeo's extconf.rb has to be told where GEOS lives; rgeo-proj4 finds PROJ
  # through pkg-config.
  geo = pkgs.mkShell {
    name = "geo";
    buildInputs = [
      pkgs.geos
      pkgs.proj
    ];
    shellHook = ''
      export GEOS_LIBRARY_PATH=${pkgs.geos}/lib
      export GEOS_INCLUDE_PATH=${pkgs.geos}/include
      true
    '';
  };

  # rmagick's extconf.rb. The dev output propagates the lib output, so headers
  # and libMagickCore are both in scope; the exports point extconf at them.
  imagemagick = pkgs.mkShell {
    name = "imagemagick";
    buildInputs = [ pkgs.imagemagick.dev ];
    shellHook = ''
      export PKG_CONFIG_PATH="${pkgs.imagemagick.dev}/lib/pkgconfig:''${PKG_CONFIG_PATH:-}"
      export CPPFLAGS="-I${pkgs.imagemagick.dev}/include/ImageMagick-7 ''${CPPFLAGS:-}"
      export LDFLAGS="-L${pkgs.imagemagick}/lib ''${LDFLAGS:-}"
      true
    '';
  };

  # karafka-rdkafka builds its librdkafka binding with autotools.
  rdkafka = pkgs.mkShell {
    name = "rdkafka";
    buildInputs = [ pkgs.rdkafka ];
    packages = with pkgs; [
      gcc
      gnumake
      autoconf
      automake
      libtool
    ];
  };

  node = pkgs.mkShell {
    name = "node";
    packages = with pkgs; [
      nodejs
      yarn
    ];
  };

  # glib for Arrow/Parquet gem builds; docker-compose for Captain's
  # container-managed services.
  misc = pkgs.mkShell {
    name = "misc";
    buildInputs = [
      pkgs.glib
      pkgs.glib.dev
    ];
    packages = [ pkgs.docker-compose ];
  };
}
