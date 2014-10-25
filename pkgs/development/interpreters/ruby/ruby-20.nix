{ stdenv, fetchurl
, zlib, zlibSupport ? true
, openssl, opensslSupport ? true
, gdbm, gdbmSupport ? true
, ncurses, readline, cursesSupport ? false
, groff, docSupport ? false
, libyaml, yamlSupport ? true
}:

let
  op = stdenv.lib.optional;
  ops = stdenv.lib.optionals;
in

stdenv.mkDerivation rec {
  version = with passthru; "${majorVersion}.${minorVersion}-p${patchLevel}";
  
  name = "ruby-${version}";
  
  src = fetchurl {
    url = "http://cache.ruby-lang.org/pub/ruby/2.0/${name}.tar.bz2";
    sha256 = "3de4e4d9aff4682fa4f8ed2b70bd0d746fae17452fc3d3a8e8f505ead9105ad9";
  };

  # Have `configure' avoid `/usr/bin/nroff' in non-chroot builds.
  NROFF = "${groff}/bin/nroff";

  buildInputs = (ops cursesSupport [ ncurses readline ] )
    ++ (op docSupport groff )
    ++ (op zlibSupport zlib)
    ++ (op opensslSupport openssl)
    ++ (op gdbmSupport gdbm)
    ++ (op yamlSupport libyaml)
    # Looks like ruby fails to build on darwin without readline even if curses
    # support is not enabled, so add readline to the build inputs if curses
    # support is disabled (if it's enabled, we already have it) and we're
    # running on darwin
    ++ (op (!cursesSupport && stdenv.isDarwin) readline);

  enableParallelBuilding = true;

  # Fix a build failure on systems with nix store optimisation.
  # (The build process attempted to copy file a overwriting file b, where a and
  # b are hard-linked, which results in cp returning a non-zero exit code.)
  # https://github.com/NixOS/nixpkgs/issues/4266
  postUnpack = ''rm "$sourceRoot/enc/unicode/name2ctype.h"'';

  patches = ops useRailsExpress [
    "${patchSet}/patches/ruby/2.0.0/p481/01-zero-broken-tests.patch"
    "${patchSet}/patches/ruby/2.0.0/p481/02-railsexpress-gc.patch"
    "${patchSet}/patches/ruby/2.0.0/p481/03-display-more-detailed-stack-trace.patch"
    "${patchSet}/patches/ruby/2.0.0/p481/04-show-full-backtrace-on-stack-overflow.patch"
    "${patchSet}/patches/ruby/2.0.0/p481/05-fix-missing-c-return-event.patch"
  ];

  configureFlags = ["--enable-shared" ]
    # on darwin, we have /usr/include/tk.h -- so the configure script detects
    # that tk is installed
    ++ ( if stdenv.isDarwin then [ "--with-out-ext=tk " ] else [ ]);

  installFlags = stdenv.lib.optionalString docSupport "install-doc";

  postInstall = ''
    # Bundler tries to create this directory
    mkdir -pv $out/${passthru.gemPath}
    mkdir -p $out/nix-support
    cat > $out/nix-support/setup-hook <<EOF
    addGemPath() {
      addToSearchPath GEM_PATH \$1/${passthru.gemPath}
    }

    envHooks+=(addGemPath)
    EOF
  '';

  meta = {
    license = "Ruby";
    homepage = "http://www.ruby-lang.org/en/";
    description = "The Ruby language";
    platforms = stdenv.lib.platforms.all;
  };

  passthru = rec {
    majorVersion = "2.0";
    minorVersion = "0";
    patchLevel = "353";
    libPath = "lib/ruby/${majorVersion}";
    gemPath = "lib/ruby/gems/${majorVersion}";
  };
}
