{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  version = "63";
  name    = "libclosure-${version}";

  src = fetchurl {
    url    = "http://www.opensource.apple.com/tarballs/libclosure/libclosure-63.tar.gz";
    sha256 = "083v5xhihkkajj2yvz0dwgbi0jl2qvzk22p7pqq1zp3ry85xagrx";
  };

  phases = [ "unpackPhase" "installPhase" ];

  installPhase = ''
    mkdir -p $out/include
    cp *.h $out/include/
  '';
}