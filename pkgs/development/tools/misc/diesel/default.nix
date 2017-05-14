{ stdenv, fetchFromGitHub, rustPlatform, makeWrapper, sqlite, postgresql, mysql }:

with rustPlatform;

buildRustPackage rec {
  name = "diesel_cli-${version}";
  version = "0.12.0";

  src = ~/.dev/Rust/diesel/* fetchFromGitHub {
    owner = "diesel-rs";
    repo = "diesel";
    rev = "891c737663b0ae4b93d6db853b48fd7ff5bca054";
    sha256 = "0nlnw6i2dk3nn7bbmkn7p6nj0r7dva6z4p9p7dcfjajp0g4h6nms";
  } */;

  buildInputs = [ sqlite postgresql mysql ];

  preBuild = "cd diesel_cli";

  postBuild = "cd ..";

  # with all features enabled the tests don't work ????
  doCheck = false;

  depsSha256 = "0z8psa0521aapb43a4s6khjjqw4hpx171h3shs180pfzr9h8lhzj";

  meta = with stdenv.lib; {
    description = "A utility that combines the usability of The Silver Searcher with the raw speed of grep";
    homepage = https://github.com/BurntSushi/ripgrep;
    license = with licenses; [ unlicense ];
    maintainers = [ maintainers.tailhook ];
    platforms = platforms.all;
  };
}
