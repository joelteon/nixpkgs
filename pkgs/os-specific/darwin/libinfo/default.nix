{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  version = "449.1.3";
  name    = "Libinfo-${version}";

  src = fetchurl {
    url    = "http://opensource.apple.com/tarballs/Libinfo/${name}.tar.gz";
    sha256 = "1ix6f7xwjnq9bqgv8w27k4j64bqn1mfhh91nc7ciiv55axpdb9hq";
  };

  phases = [ "unpackPhase" "installPhase" ];

  installPhase = ''
    substituteInPlace xcodescripts/install_files.sh \
      --replace "/usr/local/" "/" \
      --replace "/usr/" "/" \
      --replace '-o "$INSTALL_OWNER" -g "$INSTALL_GROUP"' "" \
      --replace "ln -h" "ln -n"

    export DSTROOT=$out
    sh xcodescripts/install_files.sh
  '';
}
