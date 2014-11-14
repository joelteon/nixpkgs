{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  version = "33";
  name    = "removefile-${version}";

  src = fetchurl {
    url    = "http://www.opensource.apple.com/tarballs/removefile/${name}.tar.gz";
    sha256 = "0ycvp7cnv40952a1jyhm258p6gg5xzh30x86z5gb204x80knw30y";
  };

  phases = [ "unpackPhase" "installPhase" ];

  installPhase = ''
    mkdir -p $out/include/
    cp removefile.h checkint.h $out/include/
  '';
}