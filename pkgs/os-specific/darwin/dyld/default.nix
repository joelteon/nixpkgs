{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  version = "239.4";
  name    = "dyld-${version}";

  src = fetchurl {
    url    = "http://www.opensource.apple.com/tarballs/dyld/${name}.tar.gz";
    sha256 = "07z7lyv6x0f6gllb5hymccl31zisrdhz4gqp722xcs9nhsqaqvn7";
  };

  phases = [ "unpackPhase" "installPhase" ];

  installPhase = ''
    mkdir -p $out/lib $out/include
    ln -s /usr/lib/dyld $out/lib/dyld
    cp -r include $out/
  '';

  meta = with stdenv.lib; {
    description = "Impure primitive symlinks to the Mac OS native dyld, along with headers";
    maintainers = with maintainers; [ copumpkin ];
    platforms   = platforms.darwin;
    license     = licenses.aspl20;
  };
}
