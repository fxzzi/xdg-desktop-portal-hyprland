{
  self,
  inputs,
  lib,
}: let
  ver = lib.removeSuffix "\n" (builtins.readFile ../VERSION);

  mkDate = longDate: (lib.concatStringsSep "-" [
    (builtins.substring 0 4 longDate)
    (builtins.substring 4 2 longDate)
    (builtins.substring 6 2 longDate)
  ]);

  version = ver + "+date=" + (mkDate (self.lastModifiedDate or "19700101")) + "_" + (self.shortRev or "dirty");
in {
  # List dependencies in ascending order with respect to usage (`foldr`).
  default = lib.composeManyExtensions [
    self.overlays.xdg-desktop-portal-hyprland
    self.overlays.sdbus-cpp_2
    inputs.hyprland-protocols.overlays.default
    inputs.hyprwayland-scanner.overlays.default
    inputs.hyprlang.overlays.default
    inputs.hyprutils.overlays.default
  ];

  xdg-desktop-portal-hyprland = lib.composeManyExtensions [
    (final: prev: {
      xdg-desktop-portal-hyprland = final.callPackage ./default.nix {
        stdenv = prev.gcc15Stdenv;
        inherit (final.qt6) qtbase qttools wrapQtAppsHook qtwayland;
        inherit version;
        src = self;
      };
    })
  ];

  # If `prev` already contains `sdbus-cpp_2`, do not modify the package set.
  # If the previous fixpoint does not contain the attribute,
  # create a new package attribute, `sdbus-cpp_2` by overriding `sdbus-cpp`
  # from `final` with the new version of `src`.
  #
  # This matches the naming/versioning scheme used in `nixos-unstable` as of writing (10-27-2024).
  #
  # This overlay can be applied to either a stable release of Nixpkgs, or any of the unstable branches.
  # If you're using an unstable branch (or a release one) which already has `sdbus-cpp_2`,
  # this overlay is effectively a wrapper of an identity function.
  #
  # TODO: Remove this overlay after the next stable Nixpkgs release.
  sdbus-cpp_2 = final: prev: {
    sdbus-cpp_2 =
      prev.sdbus-cpp_2
      or (final.sdbus-cpp.overrideAttrs (self: _: {
        version = "2.0.0";

        src = final.fetchFromGitHub {
          owner = "Kistler-group";
          repo = "sdbus-cpp";
          rev = "v${self.version}";
          hash = "sha256-W8V5FRhV3jtERMFrZ4gf30OpIQLYoj2yYGpnYOmH2+g=";
        };
      }));
  };
}
