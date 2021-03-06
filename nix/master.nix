let
  jupyterLib = import ../../jupyterWith {};

  haskTorchSrc = builtins.fetchGit {
    url = https://github.com/hasktorch/hasktorch;
    rev = "5f905f7ac62913a09cbb214d17c94dbc64fc8c7b";
    ref = "master";
  };

  hasktorchOverlay = (import (haskTorchSrc + "/nix/shared.nix") { compiler = "ghc883"; }).overlayShared;
  haskellOverlay = import ../overlay/haskell-overlay.nix;
  overlays = [
    # Only necessary for Haskell kernel
    (import ../overlay/python-overlay.nix)
    (import ../overlay/package-overlay.nix)
    (import ../overlay/julia.nix)
    haskellOverlay
    hasktorchOverlay
  ];


  env = import ../../jupyterWith/lib/directory.nix { inherit pkgs;};
  
  pkgs = import ../nix/nixpkgs.nix { inherit overlays; config={ allowUnfree=true; allowBroken=true; ignoreCollisions = true;};};

  jupyter = import ../../jupyterWith {pkgs=pkgs;};
  
  ihaskell_labextension = pkgs.fetchurl {
    url = "https://github.com/GTrunSec/ihaskell_labextension/releases/download/fetchurl/package.tar.gz";
    sha256 = "0i17yd3b9cgfkjxmv9rdv3s31aip6hxph5x70s04l9xidlvsp603";
  };

  iPython = jupyter.kernels.iPythonWith {
    python3 = pkgs.callPackage ../overlay/python-self-packages.nix { inherit pkgs;};
    name = "Python-data-Env";
    packages = import ../overlay/python-packages-list.nix {inherit pkgs;};
    ignoreCollisions = true;
  };

  IRkernel = jupyter.kernels.iRWith {
    name = "IRkernel-data-env";
    packages = import ../overlay/R-packages-list.nix {inherit pkgs;};
   };

  iHaskell = jupyter.kernels.iHaskellWith {
    name = "ihaskell-data-env";
    haskellPackages = pkgs.haskell.packages.ghc883;
    packages = import ../overlay/haskell-packages-list.nix {inherit pkgs;};
    Rpackages = p: with p; [ ggplot2 dplyr xts purrr cmaes cubature
                             reshape2
                           ];
    inline-r = true;
    # extraRuntimePackages = p: with p;[
    #   R
    #   rPackages.ggplot2 rPackages.dplyr rPackages.xts rPackages.purrr rPackages.cmaes rPackages.cubature
    #   rPackages.reshape2
    # ];
    # extraEnvVars = "
    #     export R_LIBS_SITE=$(echo extraEnv_PATH)/library
    #     ";
  };
  overlay_julia = [ (import ../overlay/julia.nix)
                  ];
  currentDir = builtins.getEnv "PWD";
  iJulia = jupyter.kernels.iJuliaWith {
    name =  "Julia-data-env";
    directory = "/home/gtrun/data/Jupyter-data-science-environment/.julia_pkgs";
    #nixpkgs =  import (builtins.fetchTarball "https://github.com/GTrunSec/nixpkgs/tarball/3fac6bbcf173596dbd2707fe402ab6f65469236e"){ overlays=overlay_julia;};
    NUM_THREADS = 24;
    cuda = true;
    cudaVersion = pkgs.cudatoolkit_10_2;
    nvidiaVersion = pkgs.linuxPackages.nvidia_x11;
    extraPackages = p: with p;[   # GZip.jl # Required by DataFrames.jl
      gzip
      zlib
    ];
  };

  jupyterEnvironment =
    jupyter.jupyterlabWith {
      kernels = [ iPython
                  #iHaskell
                  #IRkernel
                  #iJulia
                ];
      directory = ./jupyterlab;
      #extraPackages = p: [(iHaskell.runtimePackage.r-libs-site){}];
    };
in
pkgs.mkShell rec {
  name = "Jupyter-data-Env";
  buildInputs = [ jupyterEnvironment
                  #pkgs.python3Packages.ipywidgets
                  env.generateDirectory
                  iJulia.runtimePackages
                  ];
  
  shellHook = ''
    '';
}
