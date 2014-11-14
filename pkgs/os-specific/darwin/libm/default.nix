{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  version = "2026";
  name    = "Libm-${version}";

  src = fetchurl {
    url    = "http://www.opensource.apple.com/tarballs/Libm/${name}.tar.gz";
    sha256 = "02sd82ig2jvvyyfschmb4gpz6psnizri8sh6i982v341x6y4ysl7";
  };

  phases = [ "unpackPhase" "installPhase" ];

  installPhase = ''
    mkdir -p $out/include

    cp Source/Intel/math.h $out/include
    cp Source/Intel/fenv.h $out/include
    cp Source/complex.h    $out/include
  '';
}