{ stdenv, fetchurl, autoconf, automake, libtool
, llvm, libcxx, clang, openssl, libuuid
}:

let
  baseParams = rec {
    name = "cctools-port-${version}";
    version = "855";

    src = let
      # Should be fetchFromGitHub but it was whining so this will do for now
      owner  = "tpoechtrager";
      repo   = "cctools-port";
      rev    = "88fd4d1514b4e23cddb3409f74d09349d6ff2f3c";
    in fetchurl {
      url    = "https://github.com/${owner}/${repo}/archive/${rev}.tar.gz";
      sha256 = "0qka91xp7h16g3m20q3iraf5nnps8kq56qs5478j5zdx9ajjl5zq";
    };

    buildInputs = [
      autoconf automake libtool llvm clang openssl libuuid
    ];

    patches = [ ./ld-rpath-nonfinal.patch ./ld-ignore-rpath-link.patch ];

    enableParallelBuilding = true;

    configureFlags = [ "CXXFLAGS=-I${libcxx}/include/c++/v1" ];

    postPatch = ''
      # FIXME: there are far more absolute path references that I don't want to fix right now
      substituteInPlace cctools/configure.ac \
        --replace "-isystem /usr/local/include -isystem /usr/pkg/include" "" \
        --replace "-L/usr/local/lib" "" \
        --replace "AC_CONFIG_FILES([otool/Makefile])" ""

      substituteInPlace cctools/Makefile.am \
        --replace 'SUBDIRS=libstuff ar as misc otool ld64 $(LD_CLASSIC)' 'SUBDIRS=libstuff ar as misc ld64 $(LD_CLASSIC)'

      patchShebangs tools
      sed -i -e 's/which/type -P/' tools/*.sh
      sed -i -e 's|clang++|& -I${libcxx}/include/c++/v1|' cctools/autogen.sh

      # Workaround for https://www.sourceware.org/bugzilla/show_bug.cgi?id=11157
      cat > cctools/include/unistd.h <<EOF
      #ifdef __block
      #  undef __block
      #  include_next "unistd.h"
      #  define __block __attribute__((__blocks__(byref)))
      #else
      #  include_next "unistd.h"
      #endif
      EOF
    '';

    preConfigure = ''
      cd cctools
      sh autogen.sh
    '';

    preInstall = ''
      pushd include
      make DSTROOT=$out/include RC_OS=common install
      popd
    '';

    meta = {
      homepage = "http://www.opensource.apple.com/source/cctools/";
      description = "Mac OS X Compiler Tools (cross-platform port)";
      license = stdenv.lib.licenses.apsl20;
    };
  };
in {
  native = stdenv.mkDerivation (baseParams // {
    postInstall = ''
      cd $out/bin
      for tool in dwarfdump dsymutil; do
        ln -s /usr/bin/$tool
      done
    '';
  });

  cross =
    { cross, maloader, makeWrapper, xctoolchain}: stdenv.mkDerivation (baseParams // {
      configureFlags = baseParams.configureFlags ++ [ "--target=${cross.config}" ];

      postInstall = ''
        for tool in dyldinfo dwarfdump dsymutil; do
          ${makeWrapper}/bin/makeWrapper "${maloader}/bin/ld-mac" "$out/bin/${cross.config}-$tool" \
            --add-flags "${xctoolchain}/bin/$tool"
          ln -s "$out/bin/${cross.config}-$tool" "$out/bin/$tool"
        done
      '';
    });
}
