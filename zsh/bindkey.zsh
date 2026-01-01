#
# zshzle
#

# When ZLE is reading a command from the terminal, it may read a sequence that
# is bound to some command and is also a prefix of a longer bound string. In
# this case ZLE will wait a certain time to see if more characters are typed,
# and if not (or they don't match any longer string) it will execute the binding.
# This timeout is defined by the KEYTIMEOUT parameter; its default is 0.4 sec. 
# There is no timeout if the prefix string is not itself bound to a command.
KEYTIMEOUT=1

# Delete all existing keymaps and reset to the default state.
bindkey -d

# Selects keymap `viins` for any operations by the current command, and also
# links `viins` to `main` so that it is selected by default the next time the
# editor starts.
bindkey -v

# `man zshcontrib`
# Edit the command line using your visual editor. The editor to be used can also
# be specified using the editor style in the context of the widget. It is
# specified as an array of command and arguments:
#   zstyle :zle:edit-command-line editor gvim -f
bindkey -M viins '^v' edit-command-line
bindkey -M vicmd '^v' edit-command-line

# -M keymap:
# The keymap specifies a keymap name that is selected for any operations by the
# current command.
#   viins:   vi emulation - insert mode
#   vicmd:   vi emulation - command mode
#   viopp:   vi emulation - operator mode
#   visual:  vi emulation - selection mode
#   isearch: incremental search mode
#   command: read a command name
#   .safeL   fallback keymap

# Enter insert mode.
bindkey -M vicmd "i" vi-insert
# Move to the first non-blank character on the line and enter insert mode.
bindkey -M vicmd "I" vi-insert-bol
# Move backward one character, without changing lines.
bindkey -M vicmd "h" vi-backward-char
# Move forward one character
bindkey -M vicmd "l" vi-forward-char
# Move to the beginning of the line, without changing lines.
bindkey -M vicmd "H" vi-beginning-of-line
# Move to the end of the line. If an argument is given to this command, the
# cursor will be moved to the end of the line (argument - 1) lines down.
bindkey -M vicmd "L" vi-end-of-line
# Move down a line in the buffer, or if already at the bottom line, move to the
# next event in the history list.
bindkey -M vicmd "j" down-line-or-history
# Move up a line in the buffer, or if already at the top line, move to the
# previous event in the history list.
bindkey -M vicmd "k" up-line-or-history
# Incrementally undo the last text modification. When called from a user-defined
# widget, takes an optional argument indicating a previous state of the undo
# history as returned by UNDO_CHANGE_NO variable; modifications are undone until
# that state is reached, subject to any limit imposed by the UNDO_LIMIT_NO
# variable.
# Note that then invoked from vi command mode, the full prior change made in
# insert mode is reverted, the changes having been merged when command mode was
# selected.
bindkey -M vicmd "u" undo
# Repeat the search. The direction of the search is indicated in the mini-buffer
bindkey -M vicmd "=" vi-repeat-search
# Move to the end of the next word
bindkey -M vicmd "e" vi-forward-word-end

#
# fzf.zsh
#

#  ctrl+f : cd into the selected directory
#  alt+f  : paste the selected file path(s) into the command line
#  ctrl+r : paste the selected command from history into the command line
# !Requirements:
#   iTerm2 > Settigns > Profiles > Keys > Left option key: Esc+
#   `brew install fzf fd`
bindkey -M vicmd '^F'  fzf-custom-cd-widget
bindkey -M viins '^F'  fzf-custom-cd-widget
bindkey -M vicmd '^[f' fzf-custom-find-widget
bindkey -M viins '^[f' fzf-custom-find-widget
bindkey -M vicmd '^R'  fzf-custom-history-widget
bindkey -M viins '^R'  fzf-custom-history-widget

#
# Aloxaf/fzf-tab
#

bindkey -M viins '^I'  fzf-tab-complete
#bindkey -M viins '^X.' fzf-tab-debug

#
# hlissner/zsh-autopair
#

# Initialize zsh-autopair AFTER vi mode is set up. This ensures autopair's key
# bindings override vi's default `self-insert`, rather than being overwritten by
# `bindkey -v`.
autopair-init

#
# lazygit.zsh
#

# Bind the widget to ctrl+g for quick access from the command line.
bindkey -M viins '^G' custom_open_lazygit
