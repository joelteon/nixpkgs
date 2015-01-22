{ stdenv, fetchurl, unifdef }:

stdenv.mkDerivation rec {
  version = "76";
  name    = "CoreOSMakefiles-${version}";

  src = fetchurl {
    url    = "http://opensource.apple.com/tarballs/CoreOSMakefiles/${name}.tar.gz";
    sha256 = "0sw3w3sjil0kvxz8y86b81sz82rcd1nijayki1a1bsnsf0hz6qbf";
  };

  buildinputs = [ unifdef ];

  phases = [ "unpackPhase" "installPhase" ];

  preInstall = ''
    substituteInPlace Makefile \
      --replace "rsync -a --exclude=.svn --exclude=.git" "cp -r"

    substituteInPlace Standard/Commands.in \
      --replace "/bin/sh" "bash" \
      --replace "/usr/bin/compress" "compress" \
      --replace "/usr/bin/gzip" "gzip" \
      --replace "/bin/pax" "pax" \
      --replace "/usr/bin/tar" "tar" \
      --replace "xcrun -find" "echo" \
      --replace '$(Install_Program_Group)   -s' '$(Install_Program_Group)' \
      --replace '$(Install_Program_Mode)   -s'  '$(Install_Program_Mode)'

    substituteInPlace ReleaseControl/Common.make \
      --replace "/tmp" "$TMPDIR"

    substituteInPlace ReleaseControl/BSDCommon.make \
      --replace '$(shell xcrun -find -sdk $(SDKROOT) cc)' "cc"

    export DSTROOT=$out
  '';

}
