#!/usr/bin/env bash

set -eo pipefail

repos=(
  "https://github.com/neovim/nvim-lspconfig.git|$HOME/.local/share/nvim/site/pack/lsp/start/nvim-lspconfig"
  "https://github.com/williamboman/mason.nvim.git|$HOME/.local/share/nvim/site/pack/lsp/start/mason.nvim"
  "https://github.com/williamboman/mason-lspconfig.nvim.git|$HOME/.local/share/nvim/site/pack/lsp/start/mason-lspconfig.nvim"
  "https://github.com/hrsh7th/nvim-cmp|$HOME/.local/share/nvim/site/pack/plugins/start/nvim-cmp"
  "https://github.com/hrsh7th/cmp-nvim-lsp|$HOME/.local/share/nvim/site/pack/plugins/start/cmp-nvim-lsp"
  "https://github.com/nvim-lua/plenary.nvim|$HOME/.local/share/nvim/site/pack/plugins/start/plenary.nvim"
  "https://github.com/nvim-telescope/telescope.nvim.git|$HOME/.local/share/nvim/site/pack/plugins/start/telescope"
  "https://github.com/nvim-treesitter/nvim-treesitter.git|$HOME/.local/share/nvim/site/pack/plugins/start/nvim-treesitter"
)

for entry in "${repos[@]}"; do
  url="${entry%%|*}"
  dir="${entry##*|}"

  if [[ -d "$dir/.git" ]]; then
    echo "Updating: $dir"
    git -C "$dir" pull --ff-only
  else
    echo "Cloning: $url -> $dir"
    mkdir -p "$(dirname "$dir")"
    git clone "$url" "$dir"
  fi
done

echo "Done!"
