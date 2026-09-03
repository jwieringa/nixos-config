# Which extra layers each Rails app needs beyond Ruby and PostgreSQL, and
# which Ruby versions its worktrees pin. Adding a Ruby version is one list
# entry. Attribute names swap dots for underscores because `.` splits
# attribute paths on the CLI (`nix develop .#iris-3_2_11`).
{
  lib,
  layers,
  mkRailsShell,
}:
let
  projects = {
    iris = {
      rubyVersions = [
        "3.1.7"
        "3.2.11"
      ];
      layers = with layers; [
        redis
        geo
        imagemagick
        rdkafka
        node
      ];
    };
    kracken = {
      rubyVersions = [ "3.1.6" ];
      layers = with layers; [
        redis
        geo
        imagemagick
        rdkafka
        node
      ];
    };
  };

  attrName = project: version: "${project}-${lib.replaceStrings [ "." ] [ "_" ] version}";
in
lib.concatMapAttrs (
  project: cfg:
  lib.listToAttrs (
    map (
      rubyVersion:
      lib.nameValuePair (attrName project rubyVersion) (mkRailsShell {
        inherit project rubyVersion;
        include = cfg.layers;
      })
    ) cfg.rubyVersions
  )
) projects
