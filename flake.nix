{
  description = "Helium browser packaged for Nix";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      helium = pkgs.callPackage ./package.nix { };

      heliumApp = {
        type = "app";
        program = "${helium}/bin/helium";
        meta.description = "Run the Helium browser";
      };

    in
    {
      packages.${system} = {
        inherit helium;
        default = helium;
      };

      apps.${system} = {
        helium = heliumApp;
        default = heliumApp;
      };

      checks.${system}.helium = helium;

      devShells.${system}.default = pkgs.mkShellNoCC {
        packages = [
          pkgs.curl
          pkgs.jq
          pkgs.nix
        ];
      };

      formatter.${system} = pkgs.nixfmt;
    };
}
