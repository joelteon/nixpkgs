{ system      ? builtins.currentSystem
, allPackages ? import ../../top-level/all-packages.nix
, platform    ? null
, config      ? {}
}:

let
  fetch = { file, sha256 }: import <nix/fetchurl.nix> {
    url = "https://dl.dropboxusercontent.com/u/361503/${file}";
    inherit sha256;
    executable = true;
  };

  bootstrapFiles = {
    sh    = fetch { file = "sh";    sha256 = "1amnaql1rc6fdsxyav7hmhj8ylf4ccmgsl7v23x4sgw94pkipz78"; };
    bzip2 = fetch { file = "bzip2"; sha256 = "1f4npmrhx37jnv90by8b39727cam3n811lvglsc6da9xm80g2f5l"; };
    mkdir = fetch { file = "mkdir"; sha256 = "0x9jqf4rmkykbpkybp40x4d0v0dq99i0r5yk8096mjn1m7s7xa0p"; };
    cpio  = fetch { file = "cpio";  sha256 = "1a5s8bs14jhhmgrf4cwn92iq8sbz40qhjzj7y35ri84prp9clkc3"; };
  };
  tarball = fetch { file = "bootstrap-tools.8.cpio.bz2"; sha256 = "0n6g79mi2vxpymwbp3vpyn170ibvly2rjxc2x2q6jp98qvfr7izq"; };
in rec {
  allPackages = import ../../top-level/all-packages.nix;

  commonPreHook = ''
    export NIX_ENFORCE_PURITY=1
    export NIX_IGNORE_LD_THROUGH_GCC=1
    export NIX_DONT_SET_RPATH=1
    export NIX_NO_SELF_RPATH=1
    stripAllFlags=" " # the Darwin "strip" command doesn't know "-s"
    xargsFlags=" "
    export MACOSX_DEPLOYMENT_TARGET=10.7
    export SDKROOT=
    export CMAKE_OSX_ARCHITECTURES=x86_64
    export NIX_CFLAGS_COMPILE+=" --sysroot=/var/empty -Wno-multichar -Wno-deprecated-declarations"
  '';

  # libSystem and its transitive dependencies. Get used to this; it's a recurring theme in darwin land
  libSystemClosure = [
    "/usr/lib/libSystem.dylib"
    "/usr/lib/libSystem.B.dylib"
    "/usr/lib/libobjc.A.dylib"
    "/usr/lib/libobjc.dylib"
    "/usr/lib/libauto.dylib"
    "/usr/lib/libc++abi.dylib"
    "/usr/lib/libc++.1.dylib"
    "/usr/lib/libDiagnosticMessagesClient.dylib"
    "/usr/lib/system"
  ];

  # The one dependency of /bin/sh :(
  binShClosure = [ "/usr/lib/libncurses.5.4.dylib" ];

  bootstrapTools = derivation rec {
    inherit system tarball;

    name    = "bootstrap-tools";
    builder = bootstrapFiles.sh; # Not a filename! Attribute 'sh' on bootstrapFiles
    args    = [ ./unpack-bootstrap-tools.sh ];

    inherit (bootstrapFiles) mkdir bzip2 cpio;

    __impureHostDeps  = binShClosure ++ libSystemClosure;
  };

  stageFun = step: last: {shell             ? "${bootstrapTools}/bin/sh",
                          overrides         ? (pkgs: {}),
                          extraPreHook      ? "export LD_DYLD_PATH=${last.pkgs.darwin.dyld}/lib/dyld",
                          extraBuildInputs  ? with last.pkgs; [ xz darwin.corefoundation ],
                          allowedRequisites ? null}:
    let
      thisStdenv = import ../generic {
        inherit system config shell extraBuildInputs allowedRequisites;

        name = "stdenv-darwin-boot-${toString step}";

        cc = if isNull last then "/no-such-path" else import ../../build-support/clang-wrapper {
          inherit shell;
          inherit (last) stdenv;
          inherit (last.pkgs) libcxx libcxxabi;

          nativeTools  = true;
          nativePrefix = bootstrapTools;
          nativeLibc   = false;
          libc         = last.pkgs.darwin.libSystem;
          clang        = { name = "clang-9.9.9"; outPath = bootstrapTools; };
        };

        preHook = stage0.stdenv.lib.optionalString /*(shell == "${bootstrapTools}/bin/sh")*/ true ''
          # Don't patch #!/interpreter because it leads to retained
          # dependencies on the bootstrapTools in the final stdenv.
          dontPatchShebangs=1
        '' + ''
          ${commonPreHook}
          ${extraPreHook}
        '';
        initialPath  = [ bootstrapTools ];
        fetchurlBoot = import ../../build-support/fetchurl {
          stdenv = stage0.stdenv;
          curl   = bootstrapTools;
        };

        # The stdenvs themselves don't use mkDerivation, so I need to specify this here
        __stdenvImpureHostDeps = binShClosure ++ libSystemClosure;
        __extraImpureHostDeps  = binShClosure ++ libSystemClosure;

        extraAttrs = { inherit platform; };
        overrides  = pkgs: (overrides pkgs) // { fetchurl = thisStdenv.fetchurlBoot; };
      };

      thisPkgs = allPackages {
        inherit system platform;
        bootStdenv = thisStdenv;
      };
    in { stdenv = thisStdenv; pkgs = thisPkgs; };

  stage0 = stageFun 0 null {
    overrides = orig: with stage0; {
      darwin = orig.darwin // {
        libSystem = stdenv.mkDerivation {
          name = "bootstrap-libSystem";
          buildCommand = ''
            mkdir -p $out
            ln -s ${bootstrapTools}/lib $out/lib
            ln -s ${bootstrapTools}/include-libSystem $out/include
          '';
        };
      };

      libcxx = stdenv.mkDerivation {
        name = "bootstrap-libcxx";
        buildCommand = ''
          mkdir -p $out/lib $out/include
          ln -s ${bootstrapTools}/lib/libc++.dylib $out/lib/libc++.dylib
          ln -s ${bootstrapTools}/include/c++      $out/include/c++
        '';
      };

      libcxxabi = stdenv.mkDerivation {
        name = "bootstrap-libcxxabi";
        buildCommand = ''
          mkdir -p $out/lib
          ln -s ${bootstrapTools}/lib/libc++abi.dylib $out/lib/libc++abi.dylib
        '';
      };

      xz = stdenv.mkDerivation {
        name = "bootstrap-xz";
        buildCommand = ''
          mkdir -p $out/bin
          ln -s ${bootstrapTools}/bin/xz $out/bin/xz
        '';
      };
    };

    extraPreHook     = "";
    extraBuildInputs = [];
  };

  persistent0 = _: { inherit (stage0.pkgs) xz; };

  stage1 = with stage0; stageFun 1 stage0 {
    extraPreHook = ''
      export NIX_CFLAGS_COMPILE+=" -F${bootstrapTools}/Library/Frameworks"
      export LD_DYLD_PATH=${bootstrapTools}/lib/dyld
    '';
    extraBuildInputs = [];

    allowedRequisites =
      [ bootstrapTools ] ++ (with pkgs; [ libcxx libcxxabi ]) ++ [ pkgs.darwin.libSystem ];

    overrides = persistent0;
  };

  persistent1 = orig: with stage1.pkgs; {
    inherit
      zlib patchutils m4 scons flex perl bison unifdef unzip openssl icu python
      libxml2 gettext sharutils gmp libarchive ncurses pkg-config libedit groff
      openssh sqlite sed serf openldap db cyrus-sasl expat apr-util subversion xz
      findfreetype libssh curl cmake autoconf automake libtool ed cpio coreutils;

    darwin = orig.darwin // {
      inherit (darwin)
        dyld libSystem xnu configd libdispatch libclosure launchd;
    };
  };

  stage2 = with stage1; stageFun 2 stage1 {
    allowedRequisites =
      [ bootstrapTools ] ++
      (with pkgs; [ xz libcxx libcxxabi icu ]) ++
      (with pkgs.darwin; [ dyld libSystem corefoundation ]);

    overrides = persistent1;
  };

  persistent2 = orig: with stage2.pkgs; {
    inherit
      patchutils m4 scons flex perl bison unifdef unzip openssl python
      gettext sharutils libarchive pkg-config groff bash subversion
      openssh sqlite sed serf openldap db cyrus-sasl expat apr-util
      findfreetype libssh curl cmake autoconf automake libtool cpio
      libcxx libcxxabi;

    darwin = orig.darwin // {
      inherit (darwin)
        dyld libSystem xnu configd libdispatch libclosure launchd;
    };
  };

  stage3 = with stage2; stageFun 3 stage2 rec {
    shell = "${pkgs.bash}/bin/bash";

    allowedRequisites =
      [ bootstrapTools ] ++
      (with pkgs; [ icu bash libcxx libcxxabi ]) ++
      (with pkgs.darwin; [ dyld libSystem ]);

    overrides = persistent2;
  };

  persistent3 = orig: with stage3.pkgs; {
    inherit
      gnumake gzip gnused bzip2 gnutar gawk ed xz patch libiconv bash
      libcxxabi libcxx ncurses libffi zlib icu llvm gmp pcre gnugrep
      coreutils findutils diffutils patchutils binutils;

    llvmPackages = orig.llvmPackages // {
      inherit (llvmPackages) llvm clang;
    };

    darwin = orig.darwin // {
      inherit (darwin)
        dyld libSystem cctools corefoundation;
    };
  };

  stage4 = with stage3; import ../generic rec {
    inherit system config;
    inherit (stdenv) fetchurlBoot;

    name = "stdenv-darwin";

    preHook = ''
      ${commonPreHook}
      export LD_DYLD_PATH=${pkgs.darwin.dyld}/lib/dyld
    '';

    __stdenvImpureHostDeps = binShClosure ++ libSystemClosure;
    __extraImpureHostDeps  = binShClosure ++ libSystemClosure;

    initialPath = import ../common-path.nix { inherit pkgs; };
    shell       = "${pkgs.bash}/bin/bash";

    cc = import ../../build-support/clang-wrapper {
      inherit stdenv shell;
      nativeTools = false;
      nativeLibc  = false;
      inherit (pkgs) libcxx libcxxabi coreutils binutils;
      inherit (pkgs.llvmPackages) clang;
      libc = pkgs.darwin.libSystem;
    };

    extraBuildInputs = [ pkgs.darwin.corefoundation ];

    extraAttrs = {
      inherit platform bootstrapTools;
      libc         = pkgs.darwin.libSystem;
      shellPackage = pkgs.bash;
    };

    allowedRequisites = (with pkgs; [
      xz libcxx libcxxabi icu gmp gnumake findutils bzip2 llvm zlib libffi
      coreutils ed diffutils gnutar gzip ncurses libiconv gnused bash gawk
      gnugrep llvmPackages.clang patch pcre
    ]) ++ (with pkgs.darwin; [
      dyld libSystem corefoundation cctools
    ]);

    overrides = orig: persistent3 orig // {
      clang = cc;
      inherit cc;
    };
  };

  stdenvDarwin = stage4;
}
