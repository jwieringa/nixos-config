with import <nixpkgs> {};
stdenv.mkDerivation {
  name = "iris";
  buildInputs = [
    ruby.devEnv
    git
    sqlite
    postgresql
  ];
}
