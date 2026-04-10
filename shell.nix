# [[file:tests/testing.org::*Nix shell for testing][Nix shell for testing:2]]
{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  packages = with pkgs; [
    python313
    python313Packages.pytest
    python313Packages.pytest-asyncio
  ];
}
# Nix shell for testing:2 ends here
