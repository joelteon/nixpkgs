{ stdenv, fetchurl, icu, dyld, libdispatch, launchd, libclosure }:

stdenv.mkDerivation rec {
  version = "855.17";
  name    = "CF-${version}";

  src = fetchurl {
    url    = "http://www.opensource.apple.com/tarballs/CF/${name}.tar.gz";
    sha256 = "1sadmxi9fsvsmdyxvg2133sdzvkzwil5fvyyidxsyk1iyfzqsvln";
  };

  buildInputs = [ dyld icu libdispatch launchd libclosure ];

  preBuild = ''
    substituteInPlace Makefile \
      --replace "/usr/bin/clang" "clang" \
      --replace "-arch i386 " "" \
      --replace "/usr/bin/" "" \
      --replace "/usr/sbin/" "" \
      --replace "/bin/" "" \
      --replace "/System/Library/Frameworks/" "$out/" \
      --replace "-licucore.A" "-licui18n -licuuc" \
      --replace 'chown -RH -f root:wheel $(DSTBASE)/CoreFoundation.framework' "" \
      --replace 'chmod -RH' 'chmod -R'

    replacement=''$'#define __PTK_FRAMEWORK_COREFOUNDATION_KEY5 55\n#define _pthread_getspecific_direct(key) pthread_getspecific((key))\n#define _pthread_setspecific_direct(key, val) pthread_setspecific((key), (val))'

    substituteInPlace CFPlatform.c --replace "#include <pthread/tsd_private.h>" "$replacement"

    substituteInPlace CFRunLoop.c --replace "#include <pthread/private.h>" ""

    substituteInPlace CFURLPriv.h \
      --replace "#include <CoreFoundation/CFFileSecurity.h>" "" \
      --replace "#include <CoreFoundation/CFURLEnumerator.h>" "" \
      --replace "CFFileSecurityRef" "void *" \
      --replace "CFURLEnumeratorResult" "void *" \
      --replace "CFURLEnumeratorRef" "void *"


    export DSTROOT=$out
  '';
}
