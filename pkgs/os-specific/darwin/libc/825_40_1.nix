{ stdenv, fetchurl, ed, unifdef }:

stdenv.mkDerivation rec {
  version = "825.40.1";
  name    = "Libc-${version}";

  src = fetchurl {
    url    = "http://opensource.apple.com/tarballs/Libc/${name}.tar.gz";
    sha256 = "0xsx1im52gwlmcrv4lnhhhn9dyk5ci6g27k6yvibn9vj8fzjxwcf";
  };

  phases = [ "unpackPhase" "installPhase" ];

  buildInputs = [ ed unifdef ];

  installPhase = ''
    export SRCROOT=$PWD
    export DSTROOT=$out
    export PUBLIC_HEADERS_FOLDER_PATH=include
    export PRIVATE_HEADERS_FOLDER_PATH=include
    bash xcodescripts/headers.sh
  '';
}