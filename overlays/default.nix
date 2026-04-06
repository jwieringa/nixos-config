{ inputs }:

[
  inputs.zig.overlays.default

  (final: prev: {
    # gh CLI on stable has bugs.
    gh = inputs.nixpkgs-unstable.legacyPackages.${prev.system}.gh;
  })
]
