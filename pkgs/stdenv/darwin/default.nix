{ system      ? builtins.currentSystem
, allPackages ? import ../../top-level/all-packages.nix
, platform    ? null
, config      ? {}
}:

rec {
  allPackages = import ../../top-level/all-packages.nix;

  bootstrapTools = derivation {
    inherit system;

    name    = "trivial-bootstrap-tools";
    builder = "/bin/sh";
    args    = [ ./trivialBootstrap.sh ];

    mkdir   = "/bin/mkdir";
    ln      = "/bin/ln";
  };

  # The simplest stdenv possible to run fetchadc and get the Apple command-line tools
  stage0 = rec {
    stdenv = import ../generic {
      inherit system config;
      name         = "stdenv-darwin-boot-0";
      shell        = "/bin/bash";
      initialPath  = [ bootstrapTools ];
      fetchurlBoot = import ../../build-support/fetchurl {
        inherit stdenv;
        curl = bootstrapTools;
      };
      cc = "/no-such-path";
    };
  };

  fetchadc = import ../../build-support/fetchadc {
    stdenv = stage0.stdenv;
    curl   = bootstrapTools;
    adc_user = if config ? adc_user
      then config.adc_user
      else throw "You need an adc_user attribute in your config to download files from Apple Developer Connection";
    adc_pass = if config ? adc_pass
      then config.adc_pass
      else throw "You need an adc_pass attribute in your config to download files from Apple Developer Connection";
  };

  buildTools = (import ../../os-specific/darwin/command-line-tools {
    inherit fetchadc;
    stdenv = stage0.stdenv;
    xar    = bootstrapTools;
    gzip   = bootstrapTools;
    cpio   = bootstrapTools;
  }).impure;

  preHook = ''
    export NIX_IGNORE_LD_THROUGH_GCC=1
    export NIX_DONT_SET_RPATH=1
    export NIX_NO_SELF_RPATH=1
    dontFixLibtool=1
    stripAllFlags=" " # the Darwin "strip" command doesn't know "-s"
    xargsFlags=" "
    export MACOSX_DEPLOYMENT_TARGET=
    export SDKROOT=
    export SDKROOT_X=/ # FIXME: impure!
    export NIX_CFLAGS_COMPILE+=" --sysroot=/var/empty -idirafter $SDKROOT_X/usr/include -F$SDKROOT_X/System/Library/Frameworks -Wno-multichar -Wno-deprecated-declarations"
    export NIX_LDFLAGS_AFTER+=" -L$SDKROOT_X/usr/lib"
  '';

  # A stdenv that wraps the Apple command-line tools and our other trivial symlinked bootstrap tools
  stage1 = rec {
    stdenv = import ../generic {
      name = "stdenv-darwin-boot-1";

      inherit system config;
      inherit (stage0.stdenv) shell initialPath fetchurlBoot;

      preHook = preHook + "\n" + ''
        export NIX_LDFLAGS_AFTER+=" -L/usr/lib"
        export NIX_ENFORCE_PURITY=
      '';

      cc = import ../../build-support/clang-wrapper {
        nativeTools  = true;
        nativePrefix = "${buildTools.tools}/Library/Developer/CommandLineTools/usr";
        nativeLibc   = true;
        stdenv       = stage0.stdenv;
        libcxx       = {
          name = "libcxx-9.9.9";
          outPath = "/usr";
          abi = "/usr"; # clang-wrapper expects libcxx.abi to be non-null
        };
        shell        = "/bin/bash";
        clang        = {
          name    = "clang-9.9.9";
          gcc     = "/usr";
          outPath = "${buildTools.tools}/Library/Developer/CommandLineTools/usr";
        };
      };
    };
    pkgs = allPackages {
      inherit system platform;
      bootStdenv = stdenv;
    };
  };

  stage2 = rec {
    stdenv = import ../generic {
      name = "stdenv-darwin-boot-2";

      inherit system config;
      inherit (stage1.stdenv) shell fetchurlBoot preHook cc;

      initialPath = [ stage1.pkgs.xz ] ++ stage1.stdenv.initialPath;
    };
    pkgs = allPackages {
      inherit system platform;
      bootStdenv = stdenv;
    };
  };

  # Use stage1 to build a whole set of actual tools so we don't have to rely on the Apple prebuilt ones or
  # the ugly symlinked bootstrap tools anymore.
  stage3 = with stage2; import ../generic {
    name = "stdenv-darwin-boot-3";

    inherit system config;
    inherit (stdenv) fetchurlBoot;

    initialPath = (import ../common-path.nix) { inherit pkgs; };

    preHook = preHook + "\n" + ''
      export NIX_ENFORCE_PURITY=1
    '';

    cc = import ../../build-support/clang-wrapper {
      inherit stdenv;
      nativeTools  = false;
      nativeLibc   = true;
      inherit (pkgs) libcxx;
      binutils  = import ../../build-support/native-darwin-cctools-wrapper { inherit stdenv; };
      clang     = pkgs.llvmPackages.clang;
      coreutils = pkgs.coreutils;
      shell     = "${pkgs.bash}/bin/bash";
    };

    shell = "${pkgs.bash}/bin/bash";
  };

  stdenvDarwin = stage3;
}
