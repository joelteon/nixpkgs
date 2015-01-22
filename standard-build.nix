let
  pkgs = import ./. {};
  bootstrap-tools = import ./pkgs/stdenv/darwin/make-bootstrap-tools.nix {};
in with pkgs; {
  build = buildEnv {
    name = "standard-build";
    paths = [
      bootstrap-tools.build
      nix-exec
      gitFull
      subversion
      emacs24Macport
      texLive
      ocaml
      coq_HEAD
      tmux
      expect
      lua
      luajit
      nginx
      apacheHttpd
      redis
      postgresql
      mysql55
      iperf
      watch
      weechat
      vim
      pass
      gnupg
    ];
    ignoreCollisions = true;
  };
}
