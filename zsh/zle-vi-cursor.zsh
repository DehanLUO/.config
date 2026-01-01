# zle-keymap-select (Build-in Widget): Executed every time the keymap changes,
# i.e. the special parameter KEYMAP is set to a different value, while the line
# editor is active. Initialising the keymap when the line editor starts does not
# cause the widget to be called.
function zle-keymap-select {
  if [[ vicmd = ${KEYMAP} ]] \
    || [[ 'block' = $1 ]]; then
    echo -ne '\e[1 q'   # block cursor for command mode
  elif [[ main = ${KEYMAP} ]] \
    || [[ viins = ${KEYMAP} ]] \
    || [[ '' = ${KEYMAP} ]] \
    || [[ 'beam' = $1 ]]; then
    echo -ne '\e[5 q'   # beam cursor for insert mode02
  fi
}
# -N wideget [function]
# Create a user-defined widget. If there is already a widget with the specified
# name, it is overwritten. When the new widget is invoked from within the editor,
# the specified shell function is called.  If no function name is specified, it
# defaults to the same name as the widget.
zle -N zle-keymap-select

zle_custom_cursor_on_preexec() {
  # Use beam shape cursor for each new prompt.
  echo -ne '\e[5 q'
}

zle_custom_cursor_on_precmd() {
  # Use beam shape cursor on startup.
  echo -ne '\e[5 q'
}

# Load the standard Zsh hook management function.
autoload -Uz add-zsh-hook
# `man zshcontrib`
# Manipulating Hook Functions
# Several functions are special to the shell, as described in the section
# SPECIAL FUNCTIONS, in that they are automatically called at specific points
# during shell execution. Each has an associated array consisting of names of
# functions to be called at the same point; these are so-called `hook functions`.
# The shell function add-zsh-hook provides a simple way of adding or removing
# functions from the array.
#   precmd: Executed before each prompt.
#   preexec: Executed just after a command has been read and is about to be
#            executed.
add-zsh-hook precmd zle_custom_cursor_on_precmd
add-zsh-hook preexec zle_custom_cursor_on_preexec
