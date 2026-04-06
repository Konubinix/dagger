{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  packages = with pkgs; [
    python313
    python313Packages.pytest
    python313Packages.pytest-asyncio
    python313Packages.pyyaml
  ];
}
