---
title: "Nixos use old version software"
date: 2024-07-08T23:42:39+08:00
author: "xiantang"
# lastmod: 
# tags: []
# categories: []
# images:
#   - ./post/golang/cover.png
description:
draft: false
---

I think this is a common problem for Nixos users, because the latest version of the software may have some problems, but in Nixos channel you can only find the fixed version of the software, so how to use the old version of the software?


According to the blog post [How to use old versions of software in NixOS](https://lazamar.github.io/download-specific-package-version-with-nix/), you can use the following method to use the old version of the software:


### search for the old version of the software

You now can search old package at `https://lazamar.co.uk/nix-versions/`

For example if you wanna install `hugo` with version `v0.60.0`, you can search `hugo` and find the version you want, which is [here](https://lazamar.co.uk/nix-versions/?package=hugo&version=0.60.0&fullName=hugo-0.60.0&keyName=hugo&revision=ee355d50a38e489e722fcbc7a7e6e45f7c74ce95&channel=nixpkgs-unstable#instructions).

```nix

let
    pkgs = import (builtins.fetchTarball {
        url = "https://github.com/NixOS/nixpkgs/archive/ee355d50a38e489e722fcbc7a7e6e45f7c74ce95.tar.gz";
    }) {};

    myPkg = pkgs.hugo;
in
```


Put above code in your `configuration.nix` as below:

```nix
# { modulesPath, config, pkgs, lib, helix, ... }:
# with lib;
let
  pkgs = import (builtins.fetchTarball {
    url =
      "https://github.com/NixOS/nixpkgs/archive/ee355d50a38e489e722fcbc7a7e6e45f7c74ce95.tar.gz";
  }) { };

  hugo = pkgs.hugo;
in 
# let unstable = import <unstable> { };
#
# in {

```


Then refer to the `myPkg` in `environment.systemPackages` of `configuration.nix`:

```nix
environment.systemPackages = with pkgs; [
# ...
  myPkg
# ...
];
```


Then run `nixos-rebuild switch` to apply the changes.
