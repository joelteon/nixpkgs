{system ? builtins.currentSystem}:

with import ../../top-level/all-packages.nix {inherit system;};

rec {
  # We want coreutils without ACL support.
  coreutils_ = coreutils.override (orig: {
    aclSupport = false;
  });

  curl = import ../../tools/networking/curl {
    inherit fetchurl;
    zlibSupport = false;
    sslSupport = false;
  };

  build = stdenv.mkDerivation {
    name = "build";

    buildInputs = [nukeReferences cpio];

    buildCommand = ''
      mkdir -p $out/bin $out/lib

      # Our (fake) loader
      cp -d ${darwin.dyld}/lib/dyld $out/lib/

      # C standard library stuff
      cp -d ${darwin.libSystem}/lib/*.o $out/lib/
      cp -d ${darwin.libSystem}/lib/*.dylib $out/lib/

      cp -rL ${darwin.libSystem}/include $out
      chmod -R u+w $out/include
      cp -rL ${icu}/include*             $out/include
      cp -rL ${libiconv}/include/*       $out/include
      cp -rL ${gnugrep.pcre}/include/*   $out/include
      mv $out/include $out/include-libSystem

      # Copy coreutils, bash, etc.
      cp ${coreutils_}/bin/* $out/bin
      (cd $out/bin && rm vdir dir sha*sum pinky factor pathchk runcon shuf who whoami shred users)

      cp ${bash}/bin/bash $out/bin
      cp ${findutils}/bin/find $out/bin
      cp ${findutils}/bin/xargs $out/bin
      cp -d ${diffutils}/bin/* $out/bin
      cp -d ${gnused}/bin/* $out/bin
      cp -d ${gnugrep}/bin/* $out/bin
      cp ${gawk}/bin/gawk $out/bin
      cp -d ${gawk}/bin/awk $out/bin
      cp ${gnutar}/bin/tar $out/bin
      cp ${gzip}/bin/gzip $out/bin
      cp ${bzip2}/bin/bzip2 $out/bin
      cp -d ${gnumake}/bin/* $out/bin
      cp -d ${patch}/bin/* $out/bin

      cp -d ${gnugrep.pcre}/lib/libpcre*.dylib $out/lib
      cp -d ${libiconv}/lib/libiconv*.dylib $out/lib

      # Copy what we need of clang
      cp -d ${llvmPackages.clang}/bin/clang $out/bin
      cp -d ${llvmPackages.clang}/bin/clang++ $out/bin
      cp -d ${llvmPackages.clang}/bin/clang-3.5 $out/bin

      cp -rL ${llvmPackages.clang}/lib/clang $out/lib

      cp -d ${libcxx}/lib/libc++*.dylib $out/lib
      cp -d ${libcxxabi}/lib/libc++abi*.dylib $out/lib

      mkdir $out/include
      cp -rd ${libcxx}/include/c++     $out/include

      cp -d ${icu}/lib/libicu*.dylib $out/lib
      cp -d ${zlib}/lib/libz.*       $out/lib
      cp -d ${gmpxx}/lib/libgmp*.*   $out/lib

      # Copy binutils.
      for i in as ld ar ranlib nm strip install_name_tool; do
        cp ${darwin.cctools}/bin/$i $out/bin
      done

      cp -rd ${pkgs.darwin.corefoundation}/System $out

      chmod -R u+w $out

      nuke-refs $out/bin/*

      # Strip executables even further
      for i in $out/bin/*; do
        if test -x $i -a ! -L $i; then
          chmod +w $i

          # This is clearly a hack. Once we have an install_name_tool-alike that can patch dyld, this will be nicer.
          ${perl}/bin/perl -i -0777 -pe 's/\/nix\/store\/eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-dyld-239\.4\/lib\/dyld/\/usr\/lib\/dyld\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00/sg' $i

          strip $i || true
        fi
      done

      rpathify() {
        libs=$(/usr/bin/otool -L "$1" | tail -n +2 | grep -o "$NIX_STORE.*-\S*" | cat)

        for lib in $libs; do
          ${darwin.cctools}/bin/install_name_tool -change $lib "@rpath/$(basename $lib)" "$1"
        done
      }

      for i in $out/bin/* $out/lib/*.dylib $out/lib/clang/3.5.0/lib/darwin/*.dylib $out/System/Library/Frameworks/CoreFoundation.framework/Versions/A/CoreFoundation; do
        if test -x $i -a ! -L $i; then
          echo "Adding rpath to $i"
          rpathify $i
        fi
      done

      nuke-refs $out/lib/*
      nuke-refs $out/lib/clang/3.5.0/lib/darwin/*
      nuke-refs $out/System/Library/Frameworks/CoreFoundation.framework/Versions/A/CoreFoundation

      mkdir $out/.pack
      mv $out/* $out/.pack
      mv $out/.pack $out/pack

      mkdir $out/on-server
      (cd $out/pack && (find | cpio -o -H newc)) | bzip2 > $out/on-server/bootstrap-tools.cpio.bz2

      # mkdir $out/in-nixpkgs
      # chmod u+w $out/in-nixpkgs/*
      # strip $out/in-nixpkgs/*
      # nuke-refs $out/in-nixpkgs/*
      # bzip2 $out/in-nixpkgs/curl
    '';

    allowedReferences = [];
  };

  unpack = stdenv.mkDerivation {
    name = "unpack";

    buildCommand = ''
      /bin/mkdir $out
      /usr/bin/bzip2 -d < ${build}/on-server/bootstrap-tools.cpio.bz2 | (cd $out && /usr/bin/cpio -v -i)

      for i in $out/bin/*; do
        if ! test -L $i; then
          echo patching $i
          libs=$(/usr/bin/otool -L "$i" | tail -n +2 | grep -v libSystem | cat)

          if [ -n "$libs" ]; then
            $out/bin/install_name_tool -add_rpath $out/lib $i
          fi
        fi
      done
    '';

    allowedReferences = [ "out" ];
  };


  test = stdenv.mkDerivation {
    name = "test";

    realBuilder = "${unpack}/bin/bash";

    buildCommand = ''
      export PATH=${unpack}/bin
      ls -l
      mkdir $out
      mkdir $out/bin
      sed --version
      find --version
      diff --version
      patch --version
      make --version
      awk --version
      grep --version
      clang --version

      /bin/sh -c 'echo Hello World'

      export flags="-idirafter ${unpack}/include-libSystem --sysroot=/var/empty -isystem${unpack}/include/c++/v1"

      export CPP="clang -E $flags"
      export CC="clang $flags -Wl,-syslibroot,${unpack} -Wl,-rpath,${unpack}/lib"
      export CXX="clang++ $flags -Wl,-syslibroot,${unpack} -Wl,-rpath,${unpack}/lib"

      echo '#include <stdio.h>' >> foo.c
      echo '#include <float.h>' >> foo.c
      echo '#include <limits.h>' >> foo.c
      echo 'int main() { printf("Hello World\n"); return 0; }' >> foo.c
      $CC -o $out/bin/foo foo.c
      $out/bin/foo

      echo '#include <iostream>' >> bar.cc
      echo 'int main() { std::cout << "Hello World\n"; }' >> bar.cc
      $CXX -v -o $out/bin/bar bar.cc
      $out/bin/bar

      tar xvf ${hello.src}
      cd hello-*
      ./configure --prefix=$out
      make
      make install
    '';
  };
}
