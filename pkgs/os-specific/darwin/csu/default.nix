{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  version = "79";
  name    = "Csu-${version}";

  src = fetchurl {
    url    = "http://opensource.apple.com/tarballs/Csu/${name}.tar.gz";
    sha256 = "1hif4dz23isgx85sgh11yg8amvp2ksvvhz3y5v07zppml7df2lnh";
  };

  postUnpack = ''
    substituteInPlace $sourceRoot/Makefile \
      --replace "/usr/lib" "/lib" \
      --replace "/usr/local/lib" "/lib" \
      --replace "/usr/bin" "" \
      --replace "/bin/" ""
  '';

  installPhase = ''
    export DSTROOT=$out
    make install
  '';

  meta = with stdenv.lib; {
    description = "Apple's common startup stubs for darwin";
    maintainers = with maintainers; [ copumpkin ];
    platforms   = platforms.darwin;
    license     = licenses.aspl20;
  };
}
