{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  version = "103.92.1";
  name    = "copyfile-${version}";

  src = fetchurl {
    url    = "http://www.opensource.apple.com/tarballs/copyfile/${name}.tar.gz";
    sha256 = "15i2hw5aqx0fklvmq6avin5s00adacvzqc740vviwc2y742vrdcd";
  };

  phases = [ "unpackPhase" "installPhase" ];

  installPhase = ''
    mkdir -p $out/include/
    cp copyfile.h $out/include/
  '';
}