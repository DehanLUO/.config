# !Requirements:
#   `brew install fzf eza`

# disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false
# set descriptions format to enable group support
zstyle ':completion:*:descriptions' format '[%d]'
# set list-colors to enable filename colorizing
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# force zsh not to show completion menu, which allows fzf-tab to capture the
# unambiguous prefix
zstyle ':completion:*' menu no
# preview directory's content with eza when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
# fzf-tab doesn't inherit FZF_DEFAULT_OPTS. I manually sync desired bindings.
zstyle ':fzf-tab:*' fzf-flags \
  --bind=ctrl-t:top,change:top \
  --bind=ctrl-j:down,ctrl-k:up \
  --bind=tab:accept,btab:ignore
# switch group using `<` and `>`
zstyle ':fzf-tab:*' switch-group '<' '>'
