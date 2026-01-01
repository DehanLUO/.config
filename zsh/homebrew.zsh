# Enable Homebrew environment on non-macOS Unix systems. On macOS, Homebrew
# works out of the box: Intel installs use /usr/local/bin, which is in the
# default PATH; On Linux/Unix, Linuxbrew defaults to /home/linuxbrew/.linuxbrew-
# a path not in the system PATH—so we must manually activate it via
# 'brew shellenv'. '$OSTYPE' is a zsh-provided variable; values starting with
# 'darwin' indicate macOS.
if [[ "$OSTYPE" != "darwin"* ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# https://docs.brew.sh/Command-Not-Found
HOMEBREW_COMMAND_NOT_FOUND_HANDLER="$(
  brew --repository
  )/Library/Homebrew/command-not-found/handler.sh"
if [ -f "$HOMEBREW_COMMAND_NOT_FOUND_HANDLER" ]; then
  source "$HOMEBREW_COMMAND_NOT_FOUND_HANDLER";
fi
