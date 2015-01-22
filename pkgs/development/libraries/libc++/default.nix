{ lib, stdenv, fetchurl, cmake, libcxxabi, fixDarwinDylibNames }:

let version = "3.5.0"; in

stdenv.mkDerivation rec {
  name = "libc++-${version}";

  src = fetchurl {
    url = "http://llvm.org/releases/${version}/libcxx-${version}.src.tar.xz";
    sha256 = "1h5is2jd802344kddm45jcm7bra51llsiv9r34h0rrb3ba2dlic0";
  };

  # instead of allowing libc++ to link with /usr/lib/libc++abi.dylib,
  # force it to link with our copy
  preConfigure = stdenv.lib.optionalString stdenv.isDarwin ''
    substituteInPlace lib/CMakeLists.txt \
      --replace 'OSX_RE_EXPORT_LINE "/usr/lib/libc++abi.dylib' \
                'OSX_RE_EXPORT_LINE "${libcxxabi}/lib/libc++abi.dylib' \
      --replace '"''${CMAKE_OSX_SYSROOT}/usr/lib/libc++abi.dylib"' \
                '"${libcxxabi}/lib/libc++abi.dylib"'
  '';

  patches = [ ./darwin.patch ];

  buildInputs = [ cmake libcxxabi ] ++ lib.optional stdenv.isDarwin fixDarwinDylibNames;

  cmakeFlags =
    [ "-DCMAKE_BUILD_TYPE=Release"
      "-DLIBCXX_LIBCXXABI_INCLUDE_PATHS=${libcxxabi}/include"
      "-DLIBCXX_LIBCXXABI_LIB_PATH=${libcxxabi}/lib"
      "-DLIBCXX_LIBCPPABI_VERSION=2"
      "-DLIBCXX_CXX_ABI=libcxxabi"
    ];

  # Through some mysterious cmake voodoo, the build decides to pass in both -lc++abi and
  # a straight reference to our libc++abi.dylib, which happen to actually be different
  # during the pure-darwin stdenv bootstrap, and thus lead to our generated libc++ being
  # linked to two separate libc++abi libraries! This kills it, but there's probably a
  # cleaner way...
  preBuild = stdenv.lib.optionalString stdenv.isDarwin ''
    substituteInPlace lib/CMakeFiles/cxx.dir/link.txt \
      --replace "-lc++abi" ""
  '';

  # We also need this to prevent more spurious libc++abi linkage...
  NIX_SKIP_CXXABI = "true";

  enableParallelBuilding = true;

  inherit libcxxabi;

  setupHook = ./setup-hook.sh;

  meta = {
    homepage = http://libcxx.llvm.org/;
    description = "A new implementation of the C++ standard library, targeting C++11";
    license = "BSD";
    maintainers = [ stdenv.lib.maintainers.shlevy ];
    platforms = stdenv.lib.platforms.unix;
  };
}
