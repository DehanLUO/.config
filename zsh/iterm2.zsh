# Only proceed if the current terminal is iTerm2, as indicated by the
# TERM_PROGRAM environment variable. This avoids unnecessary operations in
# other terminals.
if [[ "iTerm.app" != "$TERM_PROGRAM" ]]; then
  # Not running in iTerm2; exit gracefully. Note: 'return' is safe only when
  # this script is sourced (e.g., from .zshrc). If used as a standalone script,
  # replace with 'exit 0'.
  return 0
fi

# Check whether the iTerm2 shell integration script is already installed.
# If not, download and execute the official installer provided by iTerm2.
if [[ ! -e "${HOME}/.iterm2_shell_integration.zsh" ]]; then
  # Fetch and run the official iTerm2 shell integration installer.
  # The script installs both the integration and utility binaries.
  curl -fsSL 'https://iterm2.com/shell_integration/install_shell_integration_and_utilities.sh' \
    | bash
fi

# Source the integration script if it exists (either pre-installed or newly set up).
# This enables features such as command tracking, directory reporting, and
# inline image display within iTerm2.
test -e "${HOME}/.iterm2_shell_integration.zsh" \
  && source "${HOME}/.iterm2_shell_integration.zsh"
