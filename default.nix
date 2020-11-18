 let
  jupyterLib = builtins.fetchGit {
    url = https://github.com/GTrunSec/jupyterWith;
    rev = "c1ccbe1b0ee5703fd425ce0a3442e7e2ecfde352";
    ref = "current";
  };

#  jupyterLibPath = "/home/co/git/jupyterWithPers/";
  jupyterLibPath = "/home/co/git/jupyterWithGTrunSec/";

  haskTorchSrc = builtins.fetchGit {
    url = https://github.com/hasktorch/hasktorch;
    rev = "5f905f7ac62913a09cbb214d17c94dbc64fc8c7b";
    ref = "master";
  };

  hasktorchOverlay = (import (haskTorchSrc + "/nix/shared.nix") { compiler = "ghc883"; }).overlayShared;
  haskellOverlay = import ./overlay/haskell-overlay.nix;

  overlays = [
    # Only necessary for Haskell kernel
    (import ./overlay/python-overlay.nix)
    (import ./overlay/package-overlay.nix)
    (import ./overlay/julia.nix)
    haskellOverlay
 #   hasktorchOverlay
  ];

  inherit (inputflake) loadInput flakeLock;
  inputflake = import ./nix/lib.nix {};


#  pkgs = (import ./nix/nixpkgs.nix) { inherit overlays; config={ allowUnfree=true; allowBroken=true; };};
  pkgs = (import (loadInput flakeLock.nixpkgs)) { inherit overlays; config={ allowUnfree=true; allowBroken=true; };};

#  jupyter = import jupyterLib {pkgs=pkgs;};
#  jupyter = import jupyterLibPath { pkgs=pkgs; };
  jupyter = (import (loadInput flakeLock.jupyterWith)){ inherit pkgs;};


  ihaskell_labextension = import ./nix/ihaskell_labextension.nix { inherit jupyter pkgs; };

#  env = (import (jupyterLib + "/lib/directory.nix")){ inherit pkgs Rpackages;};
  env = (import ((loadInput flakeLock.jupyterWith) + "/lib/directory.nix")){ inherit pkgs Rpackages;};

#  Rpackages = p: with p; [ ggplot2 dplyr xts purrr cmaes cubature
#                           reshape2 here car
#                         ];
  Rpackages = import ./overlay/R-packages-list.nix {inherit pkgs;};

  iPython = jupyter.kernels.iPythonWith {
#    python3 = pkgs.callPackage ./overlay/python-self-packages.nix { inherit pkgs;};
    name = "Python-data-env";
    packages = import ./overlay/python-packages-list.nix {inherit pkgs;};
    ignoreCollisions = true;
  };

  IRkernel = jupyter.kernels.iRWith {
    name = "IRkernel-data-env";
    packages = import ./overlay/R-packages-list.nix {inherit pkgs;};
   };

  iHaskell = jupyter.kernels.iHaskellWith {
    name = "ihaskell-data-env";
#    haskellPackages = pkgs.haskell.packages.ghc883;
    extraIHaskellFlags = "--codemirror Haskell";  # for jupyterlab syntax highlighting
    packages = import ./overlay/haskell-packages-list.nix {inherit
      pkgs;
#      Diagrams = true;
#      Hasktorch = true;
#      InlineC = false;
#      Matrix = true;
    };
#    inline-r = true;
#    inherit Rpackages;
    r-libs-site = env.r-libs-site;
    r-bin-path = env.r-bin-path;
  };

  ##julia part
  currentDir = builtins.getEnv "PWD";
  iJulia = jupyter.kernels.iJuliaWith {
    name =  "Julia-data-env";
    directory = currentDir + "/.julia_pkgs";
    ##julia_1.5.1
    NUM_THREADS = 12;
    extraPackages = p: with p;[   # GZip.jl # Required by DataFrames.jl
      gzip
      zlib
      libgit2
    ];
  };

  iNix = jupyter.kernels.iNixKernel {
    name = "nix-kernel";
  };

  jupyterEnvironment =
    jupyter.jupyterlabWith {
      kernels= [ iPython  IRkernel iJulia iNix ];
      directory = jupyter.mkDirectoryWith {
        extensions = [
#         ihaskell_labextension
         "@jupyter-widgets/jupyterlab-manager@2.0.0"
	  "jupyterlab-jupytext"
#          "@bokeh/jupyter_bokeh@2.0.0"
#          #"@jupyterlab/git@0.21.0-alpha.0"
#          "@krassowski/jupyterlab-lsp@1.1.2"
#	  "@mwouts/jupytext@1.2.3"
#          "@jupyterlab/jupyterlab-latex@2.0"
        ];
      };
      extraPackages = p: with p;[
#         python3Packages.jupyter_lsp
#         python3Packages.python-language-server
         python3Packages.jupytext
	 ];
      extraJupyterPath = p:
      #  "${p.python3Packages.jupyter_lsp}/lib/python3.7/site-packages:${p.python3Packages.python-language-server}/lib/python3.7/site-packages";
      "${p.python3Packages.jupytext}/${pkgs.python3.sitePackages}";
      };

 in
   pkgs.mkShell rec {
     name = "Jupyter-data-Env";
     buildInputs = [
       jupyterEnvironment
        pkgs.python3Packages.jupytext
	
#       pkgs.python3Packages.ipywidgets
#       pkgs.python3Packages.python-language-server
#       pkgs.python3Packages.jupyter_lsp
#       pkgs.python3Packages.jupytext
#       pkgs.python3Packages.jupyterlab_git
#       pkgs.python3Packages.jupyterlab_jupytext

       iJulia.runtimePackages
       iPython.runtimePackages
#       iHaskell.runtimePackages
       IRkernel.runtimePackages
                   ];

     shellHook = ''
       export hd=$HOME
 #      export R_LIBS_SITE=${builtins.readFile env.r-libs-site}
 #      export PATH="${pkgs.lib.makeBinPath ([ env.r-bin-path ] )}:$PATH"
       export PYTHON=python-Python-data-env
     # julia_wrapped -e 'import Pkg;Pkg.add(url="https://github.com/JuliaPy/PyCall.jl")'
     # export JULIA_DEPOT_PATH="/home/co/.julia_pkgs"
     # export JULIA_NUM_THREADS="12"
     # export JULIA_PKGDIR="/home/co/.julia_pkgs"

#      ${pkgs.python3Packages.jupyter_core}/bin/jupyter nbextension install --py widgetsnbextension --user
#      ${pkgs.python3Packages.jupyter_core}/bin/jupyter nbextension enable --py widgetsnbextension
#      ${pkgs.python3Packages.jupyter_core}/bin/jupyter serverextension enable --py jupyter_lsp
#      ${pkgs.python3Packages.jupyter_core}/bin/jupyter serverextension enable --py jupyterlab_git
#      ${pkgs.python3Packages.jupyter_core}/bin/jupyter labextension enable jupyterlab-jupytext
#      ${pkgs.python3Packages.jupyter_core}/bin/jupyter nbextension install --py jupytext --user      
#      ${pkgs.python3Packages.jupyter_core}/bin/jupyter nbextension enable jupytext --user --py
#      ${pkgs.python3Packages.jupyter_core}/bin/jupyter labextension install jupyterlab-jupytext

   #for emacs-ein to load kernels environment.
      ln -sfT ${iPython.spec}/kernels/ipython_Python-data-env ~/.local/share/jupyter/kernels/ipython_Python-data-env
      ln -sfT ${iJulia.spec}/kernels/julia_Julia-data-env ~/.local/share/jupyter/kernels/iJulia-data-env
 #     ln -sfT ${iHaskell.spec}/kernels/ihaskell_ihaskell-data-env ~/.local/share/jupyter/kernels/iHaskell-data-env
      ln -sfT ${IRkernel.spec}/kernels/ir_IRkernel-data-env ~/.local/share/jupyter/kernels/IRkernel-data-env
      ln -sfT ${iNix.spec}/kernels/inix_nix-kernel/  ~/.local/share/jupyter/kernels/INix-data-env






     #${jupyterEnvironment}/bin/jupyter-lab --ip
                 '';
   }
