---
layout: article
title: "Installing LightGBM on an M1 Macbook"
date: 2025-11-10 11:00:07 +0800
categories: Tips
tags:
    - macOS
    - Apple Silicon
    - M1
    - LightGBM
    - conda
    - conda-forge
---

# Installing LightGBM on an M1 Mac

While setting up LightGBM on my M1 Mac, I discovered that the default `pip install lightgbm` command does not work due to compatibility issues with Apple Silicon and `libomp` dependencies.

After trying various fixes, including setting environment variables and reinstalling `libomp` via Homebrew, I still encountered installation errors with:

```bash
pip install lightgbm --no-binary :all:
```

After some research, I found a solution that worked: creating a new Conda environment and installing LightGBM using Conda-Forge:

```bash
conda install \
    --yes \
    -c conda-forge \
    'lightgbm>=4.6.0'
```

This approach successfully installed LightGBM without further issues.

For more details and troubleshooting options, I found this Stack Overflow discussion useful.

Ref:

1. https://katieminjoo.github.io/posts/InstallLGBMonMacM1/