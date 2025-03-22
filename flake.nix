{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };
  outputs = {
    self,
    nixpkgs,
    rust-overlay,
  }: let
    system = "x86_64-linux";
    overlays = [(import rust-overlay)];
    pkgs = import nixpkgs {inherit system overlays;};
    rustToolchain = pkgs.rust-bin.fromRustupToolchainFile ./toolchain.toml;
    nativeBuildInputs = [rustToolchain pkgs.pkg-config]; # Things required at compile-time.
    buildInputs = [pkgs.openssl]; # Things required at run-time.
  in {
    devShells.${system}.default =
      pkgs.mkShell {inherit buildInputs nativeBuildInputs;};
  };
}
