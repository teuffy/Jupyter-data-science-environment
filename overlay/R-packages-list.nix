{ pkgs }:
(with pkgs.rWrapper.override; (p: with p;  [
  rattle
  igraph
  summarytools
  doBy
  tidyverse
  tidyquant
  devtools
  ggplot2
  xts
  uuid
  htmlwidgets
  IRdisplay
  purrr cmaes cubature
  data_table
  survey
  FactoMineR
  rmarkdown
  sampling
  Ryacas
  HistData
  e1071
  plotrix
  sampling
  TeachingSampling
  quantmod
  moments
#  multicore
#  parallel
#  pewmethods
#  DASL
  jsonlite
#  here
  (let

    llr = buildRPackage {
      name = "llr";
        src = pkgs.fetchFromGitHub {

          owner = "dirkschumacher";

          repo = "llr";

          rev = "0a654d469af231e9017e1100f00df47bae212b2c";

          sha256 = "0ks96m35z73nf2sb1cb8d7dv8hq8dcmxxhc61dnllrwxqq9m36lr";

        };

        
       propagatedBuildInputs = [ rlang  knitr];

       nativeBuildInputs = [ rlang knitr ];
    };
    pewmethods = buildRPackage {
      name = "pewmethods";
        src = pkgs.fetchFromGitHub {

          owner = "pewresearch";

          repo = "pewmethods";

          rev = "d7c0481736d1b8453b0f186f2ebdfd6b01c172f4";

          sha256 = "0ki99r4izs9w5fj9k34ngidsfarjb1dx0fvp1m5q2k2gc2d5h6ga";

        };

        
       propagatedBuildInputs = [ rlang knitr dplyr tibble purrr forcats haven survey mice ranger openxlsx ];

       nativeBuildInputs = [ rlang knitr dplyr tibble purrr forcats haven survey mice ranger openxlsx ];
    };    

  in

    [llr pewmethods]

  )
 
  ]))
