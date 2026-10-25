{
  description = "STATEC Logement en chiffres - deuxième trimestre 2026";

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org"
      "https://rstats-on-nix.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "rstats-on-nix.cachix.org-1:vdiiVgocg6WeJrODIqdprZRUrhi1JzhBnXv7aWI6+F0="
    ];
  };

  inputs = {
    nixpkgs.url = "github:rstats-on-nix/nixpkgs/2026-09-04";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };

        rEnv = pkgs.rWrapper.override {
          packages = with pkgs.rPackages; [
            readxl
            dplyr
            tidyr
            purrr
            stringr
            janitor
            jsonlite
            knitr
            rmarkdown
          ];
        };

        pythonEnv = pkgs.python3.withPackages (
          ps: with ps; [
            openpyxl 
          ]
        );
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            rEnv
            pkgs.quarto
            pkgs.pandoc
            pkgs.poppler-utils
            pythonEnv
          ];
          QUARTO_R = "${rEnv}/bin/R";
        };
      }
    );
}
