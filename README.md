Nixpkgs is a collection of packages for [Nix](http://nixos.org/nix/) package
manager. Nixpkgs also includes [NixOS](http://nixos.org/nixos/) linux distribution source code.

* [NixOS installation instructions](http://nixos.org/nixos/manual/#ch-installation)
* [Manual (How to write packages for Nix)](http://nixos.org/nixpkgs/manual/)
* [Manual (NixOS)](http://nixos.org/nixos/manual/)
* [Continuous build](http://hydra.nixos.org/jobset/nixos/trunk-combined)
* [Tests](http://hydra.nixos.org/job/nixos/trunk-combined/tested#tabs-constituents)
* [Mailing list](http://lists.science.uu.nl/mailman/listinfo/nix-dev)
* [IRC - #nixos on freenode.net](irc://irc.freenode.net/#nixos)

# Darwin stdenv notes

This fork of nixpkgs is intended to provide a purer stdenv for Darwin,
suitable for building packages on Yosemite.

The following is a list of known, major issues yet to be resolved.

## Broken subversion

The subversion that Nix builds is broken, which in turn causes many
packages to fail.  As a very hackish workaround, you can do the following,
after building the subversion derivation:
 
    find /nix/store/ -name svn -type f \
        | grep -v Developer \
        | while read file; do sudo cp -p /usr/bin/svn $file ; done
