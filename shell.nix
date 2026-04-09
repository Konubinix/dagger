# [[file:tests/testing.org::*Nix shell for host testing][Nix shell for host testing:2]]
{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  packages = with pkgs; [
    python313
    python313Packages.pytest
    python313Packages.pytest-asyncio
    python313Packages.pyyaml
  ];
}
# Nix shell for host testing:2 ends here
