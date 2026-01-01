# !Requirements
#   `brew install lazygit`

# Define a helper function to run commands cleanly within ZLE (Zsh Line Editor).
function zle_eval {
  # Clear the current terminal line and move cursor to the beginning.
  echo -en "\e[2K\r"
  # Execute the command(s) passed as arguments (e.g., "lazygit").
  eval "$@"
  # Redraw the Zsh command line to restore any user input in progress.
  zle redisplay
}

# Define a custom ZLE widget that launches the 'lazygit' TUI tool.
function custom_open_lazygit {
  # Invoke lazygit using the safe zle_eval wrapper.
  zle_eval lazygit
}
# Register 'custom_open_lazygit' as a valid ZLE widget.
zle -N custom_open_lazygit

