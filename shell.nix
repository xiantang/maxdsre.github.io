with import <nixpkgs> { };

mkShell {
  buildInputs = [
    (hugo.overrideAttrs (oldAttrs: rec {
      version = "0.59.0";
      src = fetchFromGitHub {
        owner = "gohugoio";
        repo = "hugo";
        rev = "v${version}";
        sha256 = "1ybb5zbdxp3rmhqxn0dj1mh5ng0h23kj7bq8k8p85qinfj2x3nx2"; # 需要更新
      };
    }))
  ];
}
