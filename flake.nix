{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  outputs =
    { self, nixpkgs }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      cc65-git = pkgs.cc65.overrideAttrs (_: {
        version = "git";
        src = pkgs.fetchFromGitHub {
          owner = "cc65";
          repo = "cc65";
          rev = "80ff9d3f4d6f1a4711ede8b6250374955ed7adb6";
          hash = "sha256-NGsnD9BocDmkZuqp5XRY+h+462tm15kRYeF9SVyvUBg=";
        };
      });
    in
    {
      devShells.x86_64-linux.default = pkgs.mkShell {
        packages = [ cc65-git ];
      };
    };
}
