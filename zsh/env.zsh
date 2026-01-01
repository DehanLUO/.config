# Enable Homebrew environment on non-macOS Unix systems. On macOS, Homebrew
# works out of the box: Intel installs use /usr/local/bin, which is in the
# default PATH; On Linux/Unix, Linuxbrew defaults to /home/linuxbrew/.linuxbrew-
# a path not in the system PATH—so we must manually activate it via
# 'brew shellenv'. '$OSTYPE' is a zsh-provided variable; values starting with
# 'darwin' indicate macOS.
if [[ "$OSTYPE" != "darwin"* ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# LS_COLORS for colored file types in terminal completions and ls output.
eval "$(gdircolors)" #< export LS_COLORS

# llvm (homebrew)
export PATH="/usr/local/opt/llvm/bin:$PATH"

# disable homebrew auto update
export HOMEBREW_NO_AUTO_UPDATE=1
