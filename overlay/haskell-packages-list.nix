{pkgs}:
#(with pkgs.haskellPackages.ghcWithPackages; (p: with p;
(p: with p;
  [hvega
   formatting

   inline-r


#   libtorch-ffi_cpu

   inline-c

   inline-c-cpp

#   hasktorch-examples_cpu

#   hasktorch_cpu

   matrix

   hmatrix

   monad-bayes

   hvega

   statistics

   vector

   ihaskell-hvega

   aeson

   aeson-pretty

   formatting

   foldl

   hlint

   histogram-fill

   #funflow

   JuicyPixels

   lens

 #  random-fu

 #  random-fu-multivariate

  ])
# )
