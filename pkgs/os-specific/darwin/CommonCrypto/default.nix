{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  version = "60049";
  name    = "CommonCrypto-${version}";

  src = fetchurl {
    url    = "http://opensource.apple.com/tarballs/CommonCrypto/${name}.tar.gz";
    sha256 = "1azin6w7cnzl0iv8kd2qzgwcp6a45zy64y5z1i6jysjcl6xmlw2h";
  };

  phases = [ "unpackPhase" "installPhase" ];

  installPhase = ''
    mkdir -p $out/include/CommonCrypto
    cp include/* $out/include/CommonCrypto
  '';

  meta = with stdenv.lib; {
    maintainers = with maintainers; [ copumpkin ];
    platforms   = platforms.darwin;
    license     = licenses.aspl20;
  };
}
