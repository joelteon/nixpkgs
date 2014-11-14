{ stdenv, fetchurl, bootstrap_cmds, bison, flex, gnum4, unifdef }:

stdenv.mkDerivation rec {
  version = "2422.115.4";
  name    = "xnu-${version}";

  src = fetchurl {
    url    = "http://opensource.apple.com/tarballs/xnu/${name}.tar.gz";
    sha256 = "1ssw5fzvgix20bw6y13c39ib0zs7ykpig3irlwbaccpjpci5jl0s";
  };

  phases = [ "unpackPhase" "patchPhase" "installPhase" ];

  buildInputs = [ bootstrap_cmds bison flex gnum4 unifdef ];

  patchPhase = ''
    substituteInPlace makedefs/MakeInc.cmd \
      --replace "/usr/bin/" "" \
      --replace "/bin/" "" \
      --replace "-Werror " ""

    substituteInPlace makedefs/MakeInc.def \
      --replace "-c -S -m" "-c -m"

    substituteInPlace libkern/kxld/Makefile \
      --replace "-Werror " ""

    substituteInPlace SETUP/kextsymboltool/Makefile \
      --replace "-lstdc++" "-lc++"

    substituteInPlace libsyscall/xcodescripts/mach_install_mig.sh \
      --replace "/usr/include" "/include" \
      --replace "/usr/local/include" "/include" \
      --replace "MIG=" "# " \
      --replace "MIGCC=" "# " \
      --replace " -o 0" "" \
      --replace '$SRC/$mig' '-I$DSTROOT/include $SRC/$mig' \
      --replace '$SRC/servers/netname.defs' '-I$DSTROOT/include $SRC/servers/netname.defs'
  '';

  installPhase = ''
    # This is a bit of a hack...
    mkdir -p sdk/usr/local/libexec

    cat > sdk/usr/local/libexec/availability.pl <<EOF
      #!$SHELL
      if [ "\$1" == "--macosx" ]; then
        echo 10.0 10.1 10.2 10.3 10.4 10.5 10.6 10.7 10.8 10.9
      elif [ "\$1" == "--ios" ]; then
        echo 2.0 2.1 2.2 3.0 3.1 3.2 4.0 4.1 4.2 4.3 5.0 5.1 6.0 6.1 7.0
      fi
    EOF
    chmod +x sdk/usr/local/libexec/availability.pl

    export SDKROOT_RESOLVED=$PWD/sdk
    export HOST_SDKROOT_RESOLVED=$PWD/sdk
    export PLATFORM=MacOSX
    export SDKVERSION=10.7

    export CC=cc
    export CXX=c++
    export MIG=${bootstrap_cmds}/bin/mig
    export MIGCOM=${bootstrap_cmds}/libexec/migcom
    export STRIP=sentinel-missing
    export LIPO=sentinel-missing
    export LIBTOOL=sentinel-missing
    export NM=sentinel-missing
    export UNIFDEF=${unifdef}/bin/unifdef
    export DSYMUTIL=sentinel-missing
    export CTFCONVERT=sentinel-missing
    export CTFMERGE=sentinel-missing
    export CTFINSERT=sentinel-missing
    export NMEDIT=sentinel-missing

    export HOST_OS_VERSION=10.7
    export HOST_CC=cc
    export HOST_FLEX=${flex}/bin/flex
    export HOST_BISON=${bison}/bin/bison
    export HOST_GM4=${gnum4}/bin/m4
    export HOST_CODESIGN='echo dummy_codesign'
    export HOST_CODESIGN_ALLOCATE=echo

    export DSTROOT=$out
    make installhdrs

    mv $out/usr/include $out
    rmdir $out/usr

    # TODO: figure out why I need to do this
    cp libsyscall/wrappers/gethostuuid*.h $out/include

    # Build the mach headers we crave
    export MIGCC=cc
    export ARCHS="x86_64"
    export SRCROOT=$PWD/libsyscall
    export DERIVED_SOURCES_DIR=$out/include
    export SDKROOT=$out
    libsyscall/xcodescripts/mach_install_mig.sh
  '';
}
