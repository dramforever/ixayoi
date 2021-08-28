{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }: {
    devShell.x86_64-linux =
      nixpkgs.legacyPackages.x86_64-linux.callPackage ./env.nix {};
  };
}
