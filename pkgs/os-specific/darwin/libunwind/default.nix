{ stdenv, fetchurl, dyld }:

stdenv.mkDerivation rec {
  version = "35.3";
  name    = "libunwind-${version}";

  src = fetchurl {
    url    = "http://opensource.apple.com/tarballs/libunwind/${name}.tar.gz";
    sha256 = "0miffaa41cv0lzf8az5k1j1ng8jvqvxcr4qrlkf3xyj479arbk1b";
  };

  phases = [ "unpackPhase" "buildPhase" "installPhase" ];

  buildInputs = [ dyld ];

  buildPhase = ''
    # cd src
    # cc -I$PWD/../include -c libuwind.cxx
    # cc -I$PWD/../include -c Registers.s
    # cc -I$PWD/../include -c unw_getcontext.s
    # cc -I$PWD/../include -c UnwindLevel1.c
    # cc -I$PWD/../include -c UnwindLevel1-gcc-ext.c
    # cc -I$PWD/../include -c Unwind-sjlj.c
  '';

  installPhase = ''
    mkdir -p $out

    cp -r include $out
  '';

  meta = with stdenv.lib; {
    maintainers = with maintainers; [ copumpkin ];
    platforms   = platforms.darwin;
    license     = licenses.apsl20;
  };
}
