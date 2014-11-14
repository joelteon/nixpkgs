{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  version = "9A581";
  name    = "CarbonHeaders-${version}";

  src = fetchurl {
    url    = "http://www.opensource.apple.com/tarballs/CarbonHeaders/${name}.tar.gz";
    sha256 = "1hc0yijlpwq39x5bic6nnywqp2m1wj1f11j33m2q7p505h1h740c";
  };

  phases = [ "unpackPhase" "installPhase" ];

  installPhase = ''
    mkdir -p $out/include
    cp MacTypes.h          $out/include
    cp ConditionalMacros.h $out/include

    substituteInPlace $out/include/MacTypes.h \
      --replace "CarbonCore/" ""
  '';

  meta = with stdenv.lib; {
    maintainers = with maintainers; [ copumpkin ];
    platforms   = platforms.darwin;
    license     = licenses.aspl20;
  };
}
