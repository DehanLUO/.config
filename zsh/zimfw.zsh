# Install zimfw via Homebrew if not already installed.
if ! brew list --formula zimfw &>/dev/null; then
  brew install zimfw
  ln -s ~/.config/zsh/zimrc ~/.zimrc
fi

# [zimfw](https://github.com/zimfw/zimfw?tab=readme-ov-file#homebrew)
ZIM_HOME=${ZDOTDIR:-${HOME}}/.zim
# Install missing modules and update ${ZIM_HOME}/init.zsh if missing or outdated.
if [[ ! ${ZIM_HOME}/init.zsh \
  -nt ${ZIM_CONFIG_FILE:-${ZDOTDIR:-${HOME}}/.zimrc} ]]; then
  source "$(brew --prefix zimfw)/share/zimfw.zsh" init
fi
# Initialize modules.
source ${ZIM_HOME}/init.zsh
