with import <nixpkgs> {};
stdenv.mkDerivation {
  name = "ruby-ror-with-mysql";
  buildInputs = [
    ruby.devEnv
    git
    sqlite
    postgresql
    mysql80
  ];
}
