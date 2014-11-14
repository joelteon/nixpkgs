{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  version = "842.92.1";
  name    = "launchd-${version}";

  src = fetchurl {
    url    = "http://www.opensource.apple.com/tarballs/launchd/${name}.tar.gz";
    sha256 = "0w30hvwqq8j5n90s3qyp0fccxflvrmmjnicjri4i1vd2g196jdgj";
  };

  phases = [ "unpackPhase" "installPhase" ];

  # No clue why the same file has two different names. Ask Apple!
  installPhase = ''
    mkdir -p $out/include/ $out/include/servers
    cp liblaunch/*.h $out/include

    cp liblaunch/bootstrap.h $out/include/servers
    cp liblaunch/bootstrap.h $out/include/servers/bootstrap_defs.h
  '';
}