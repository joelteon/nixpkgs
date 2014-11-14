{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  version = "265";
  name    = "architecture-${version}";

  src = fetchurl {
    url    = "http://opensource.apple.com/tarballs/architecture/${name}.tar.gz";
    sha256 = "05wz8wmxlqssfp29x203fwfb8pgbdjj1mpz12v508658166yzqj8";
  };

  phases = [ "unpackPhase" "installPhase" ];

  postUnpack = ''
    substituteInPlace $sourceRoot/Makefile \
      --replace "/usr/include" "/include" \
      --reaplce "/usr/bin/" ""
  '';

  installPhase = ''
    export DSTROOT=$out
    make install
  '';

  meta = with stdenv.lib; {
    maintainers = with maintainers; [ copumpkin ];
    platforms   = platforms.darwin;
    license     = licenses.aspl20;
  };
}
