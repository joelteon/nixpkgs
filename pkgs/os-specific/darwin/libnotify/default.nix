{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  version = "121.20.1";
  name    = "Libnotify-${version}";

  src = fetchurl {
    url    = "http://www.opensource.apple.com/tarballs/Libnotify/${name}.tar.gz";
    sha256 = "164rx4za5z74s0mk9x0m1815r1m9kfal8dz3bfaw7figyjd6nqad";
  };

  phases = [ "unpackPhase" "installPhase" ];

  installPhase = ''
    mkdir -p $out/include
    cp notify.h      $out/include
    cp notify_keys.h $out/include
  '';
}
