{ pkgs ? import <nixpkgs> {}
, nixpkgs-hardenedlinux
, jupyterWith
}:
let

  jupyter = import jupyterWith { inherit pkgs;};
  env = (import (jupyterWith + "/lib/directory.nix")){ inherit pkgs Rpackages;};

  Rpackages = p: with p; [];


  iPython = jupyter.kernels.iPythonWith {
    python3 = pkgs.callPackage ./overlays/python-self-packages.nix { inherit pkgs;};
    name = "Python-data-env";
    ignoreCollisions = true;
  };


  iHaskell = jupyter.kernels.iHaskellWith {
    extraIHaskellFlags = "--codemirror Haskell";  # for jupyterlab syntax highlighting
    name = "ihaskell-flake";
    r-libs-site = env.r-libs-site;
    r-bin-path = env.r-bin-path;
  };

  jupyterEnvironment =
    jupyter.jupyterlabWith {
      kernels = [ iPython ];
    };
  voila = pkgs.writeScriptBin "voila" ''
    nix-shell ${nixpkgs-hardenedlinux}/pkgs/python/env/voila --command "voila"
  '';
in
pkgs.mkShell rec {
  buildInputs = [
    voila
    jupyterEnvironment
  ];
}

# let
#   jupyterLib = builtins.fetchGit {
#     url = https://github.com/tweag/jupyterWith;
#     rev = "dc8bb19f3f850c903fe481cbc7efc0982e6afd28";
#     ref = "master";
#   };

#   overlays = [
#     # Only necessary for Haskell kernel
#     (import ./overlay/python-overlay.nix)
#   ];

#   pkgs = (import (jupyterLib + "/nix/nixpkgs.nix")) { inherit overlays; config={ allowUnfree=true; allowBroken=true; };};
#   jupyter = import jupyterLib {pkgs=pkgs;};

#   iPython = jupyter.kernels.iPythonWith {
#     name = "notebook";
#     python3 = pkgs.callPackage ../overlay/python-self-packages.nix { inherit pkgs;};
#     packages = import ../overlay/python-packages-list.nix { inherit pkgs;};

#     ##for geoip2 package
#     ignoreCollisions = true;
#   };

#   iRKernel = jupyter.kernels.iRWith {
#     name = "notebook";
#     packages = p: with p; [
#       cowplot
#       dplyr
#       ggplot2
#     ];
#   };

#   jupyterEnvironment =
#     jupyter.jupyterlabWith {
#       kernels = [
#         iPython
#         iRKernel
#       ];
#       directory = ./jupyterlab;
#       extraPackages = p: [
#         p.python3Packages.jupytext
#       ];
#       extraJupyterPath = p: "${p.python3Packages.jupytext}/lib/python3.7/site-packages";
#     };
# in
#   jupyterEnvironment.env
