### key-bindings.zsh ###
#     ____      ____
#    / __/___  / __/
#   / /_/_  / / /_
#  / __/ / /_/ __/
# /_/   /___/_/ key-bindings.zsh
#
# - $FZF_TMUX_OPTS
# - $FZF_CTRL_T_COMMAND
# - $FZF_CTRL_T_OPTS
# - $FZF_CTRL_R_COMMAND
# - $FZF_CTRL_R_OPTS
# - $FZF_ALT_C_COMMAND
# - $FZF_ALT_C_OPTS


# Key bindings
# ------------

# The code at the top and the bottom of this file is the same as in completion.zsh.
# Refer to that file for explanation.
if 'zmodload' 'zsh/parameter' 2>'/dev/null' && (( ${+options} )); then
  __fzf_key_bindings_options="options=(${(j: :)${(kv)options[@]}})"
else
  () {
    __fzf_key_bindings_options="setopt"
    'local' '__fzf_opt'
    for __fzf_opt in "${(@)${(@f)$(set -o)}%% *}"; do
      if [[ -o "$__fzf_opt" ]]; then
        __fzf_key_bindings_options+=" -o $__fzf_opt"
      else
        __fzf_key_bindings_options+=" +o $__fzf_opt"
      fi
    done
  }
fi

'builtin' 'emulate' 'zsh' && 'builtin' 'setopt' 'no_aliases'

{
if [[ -o interactive ]]; then

#----BEGIN INCLUDE common.sh
# NOTE: Do not directly edit this section, which is copied from "common.sh".
# To modify it, one can edit "common.sh" and run "./update.sh" to apply
# the changes. See code comments in "common.sh" for the implementation details.

__fzf_defaults() {
  printf '%s\n' "--height ${FZF_TMUX_HEIGHT:-40%} --min-height 20+ --bind=ctrl-z:ignore $1"
  command cat "${FZF_DEFAULT_OPTS_FILE-}" 2> /dev/null
  printf '%s\n' "${FZF_DEFAULT_OPTS-} $2"
}

__fzf_exec_awk() {
  if [[ -z ${__fzf_awk-} ]]; then
    __fzf_awk=awk
    if [[ $OSTYPE == solaris* && -x /usr/xpg4/bin/awk ]]; then
      __fzf_awk=/usr/xpg4/bin/awk
    elif command -v mawk > /dev/null 2>&1; then
      local n x y z d
      IFS=' .' read -r n x y z d <<< $(command mawk -W version 2> /dev/null)
      [[ $n == mawk ]] &&
        (((x * 1000 + y) * 1000 + z >= 1003004)) 2> /dev/null &&
        ((d >= 20230302)) 2> /dev/null &&
        __fzf_awk=mawk
    fi
  fi
  LC_ALL=C exec "$__fzf_awk" "$@"
}
#----END INCLUDE

# CTRL-T - Paste the selected file path(s) into the command line
__fzf_select() {
  setopt localoptions pipefail no_aliases 2> /dev/null
  local item
  FZF_DEFAULT_COMMAND=${FZF_CTRL_T_COMMAND:-} \
  FZF_DEFAULT_OPTS=$(__fzf_defaults "--reverse --walker=file,dir,follow,hidden --scheme=path" "${FZF_CTRL_T_OPTS-} -m") \
  FZF_DEFAULT_OPTS_FILE='' $(__fzfcmd) "$@" < /dev/tty | while read -r item; do
    echo -n -E "${(q)item} "
  done
  local ret=$?
  echo
  return $ret
}

__fzfcmd() {
  [ -n "${TMUX_PANE-}" ] && { [ "${FZF_TMUX:-0}" != 0 ] || [ -n "${FZF_TMUX_OPTS-}" ]; } &&
    echo "fzf-tmux ${FZF_TMUX_OPTS:--d${FZF_TMUX_HEIGHT:-40%}} -- " || echo "fzf"
}

fzf-file-widget() {
  LBUFFER="${LBUFFER}$(__fzf_select)"
  local ret=$?
  zle reset-prompt
  return $ret
}
if [[ "${FZF_CTRL_T_COMMAND-x}" != "" ]]; then
  zle     -N            fzf-file-widget
  bindkey -M emacs '^T' fzf-file-widget
  bindkey -M vicmd '^T' fzf-file-widget
  bindkey -M viins '^T' fzf-file-widget
fi

# ALT-C - cd into the selected directory
fzf-cd-widget() {
  setopt localoptions pipefail no_aliases 2> /dev/null
  local dir="$(
    FZF_DEFAULT_COMMAND=${FZF_ALT_C_COMMAND:-} \
    FZF_DEFAULT_OPTS=$(__fzf_defaults "--reverse --walker=dir,follow,hidden --scheme=path" "${FZF_ALT_C_OPTS-} +m") \
    FZF_DEFAULT_OPTS_FILE='' $(__fzfcmd) < /dev/tty)"
  if [[ -z "$dir" ]]; then
    zle redisplay
    return 0
  fi
  zle push-line # Clear buffer. Auto-restored on next prompt.
  BUFFER="builtin cd -- ${(q)dir:a}"
  zle accept-line
  local ret=$?
  unset dir # ensure this doesn't end up appearing in prompt expansion
  zle reset-prompt
  return $ret
}
if [[ "${FZF_ALT_C_COMMAND-x}" != "" ]]; then
  zle     -N             fzf-cd-widget
  bindkey -M emacs '\ec' fzf-cd-widget
  bindkey -M vicmd '\ec' fzf-cd-widget
  bindkey -M viins '\ec' fzf-cd-widget
fi

# CTRL-R - Paste the selected command from history into the command line
fzf-history-widget() {
  local selected
  setopt localoptions noglobsubst noposixbuiltins pipefail no_aliases noglob nobash_rematch 2> /dev/null
  # Ensure the module is loaded if not already, and the required features, such
  # as the associative 'history' array, which maps event numbers to full history
  # lines, are set. Also, make sure Perl is installed for multi-line output.
  if zmodload -F zsh/parameter p:{commands,history} 2>/dev/null && (( ${+commands[perl]} )); then
    selected="$(printf '%s\t%s\000' "${(kv)history[@]}" |
      perl -0 -ne 'if (!$seen{(/^\s*[0-9]+\**\t(.*)/s, $1)}++) { s/\n/\n\t/g; print; }' |
      FZF_DEFAULT_OPTS=$(__fzf_defaults "" "-n2..,.. --scheme=history --bind=ctrl-r:toggle-sort,alt-r:toggle-raw --wrap-sign '\t↳ ' --highlight-line ${FZF_CTRL_R_OPTS-} --query=${(qqq)LBUFFER} +m --read0") \
      FZF_DEFAULT_OPTS_FILE='' $(__fzfcmd))"
  else
    selected="$(fc -rl 1 | __fzf_exec_awk '{ cmd=$0; sub(/^[ \t]*[0-9]+\**[ \t]+/, "", cmd); if (!seen[cmd]++) print $0 }' |
      FZF_DEFAULT_OPTS=$(__fzf_defaults "" "-n2..,.. --scheme=history --bind=ctrl-r:toggle-sort,alt-r:toggle-raw --wrap-sign '\t↳ ' --highlight-line ${FZF_CTRL_R_OPTS-} --query=${(qqq)LBUFFER} +m") \
      FZF_DEFAULT_OPTS_FILE='' $(__fzfcmd))"
  fi
  local ret=$?
  if [ -n "$selected" ]; then
    if [[ $(__fzf_exec_awk '{print $1; exit}' <<< "$selected") =~ ^[1-9][0-9]* ]]; then
      zle vi-fetch-history -n $MATCH
    else # selected is a custom query, not from history
      LBUFFER="$selected"
    fi
  fi
  zle reset-prompt
  return $ret
}
if [[ ${FZF_CTRL_R_COMMAND-x} != "" ]]; then
  if [[ -n ${FZF_CTRL_R_COMMAND-} ]]; then
    echo "warning: FZF_CTRL_R_COMMAND is set to a custom command, but custom commands are not yet supported for CTRL-R" >&2
  fi
  zle     -N            fzf-history-widget
  bindkey -M emacs '^R' fzf-history-widget
  bindkey -M vicmd '^R' fzf-history-widget
  bindkey -M viins '^R' fzf-history-widget
fi
fi

} always {
  eval $__fzf_key_bindings_options
  'unset' '__fzf_key_bindings_options'
}
### end: key-bindings.zsh ###
### completion.zsh ###
#     ____      ____
#    / __/___  / __/
#   / /_/_  / / /_
#  / __/ / /_/ __/
# /_/   /___/_/ completion.zsh
#
# - $FZF_TMUX                 (default: 0)
# - $FZF_TMUX_OPTS            (default: empty)
# - $FZF_COMPLETION_TRIGGER   (default: '**')
# - $FZF_COMPLETION_OPTS      (default: empty)
# - $FZF_COMPLETION_PATH_OPTS (default: empty)
# - $FZF_COMPLETION_DIR_OPTS  (default: empty)


# Both branches of the following `if` do the same thing -- define
# __fzf_completion_options such that `eval $__fzf_completion_options` sets
# all options to the same values they currently have. We'll do just that at
# the bottom of the file after changing options to what we prefer.
#
# IMPORTANT: Until we get to the `emulate` line, all words that *can* be quoted
# *must* be quoted in order to prevent alias expansion. In addition, code must
# be written in a way works with any set of zsh options. This is very tricky, so
# careful when you change it.
#
# Start by loading the builtin zsh/parameter module. It provides `options`
# associative array that stores current shell options.
if 'zmodload' 'zsh/parameter' 2>'/dev/null' && (( ${+options} )); then
  # This is the fast branch and it gets taken on virtually all Zsh installations.
  #
  # ${(kv)options[@]} expands to array of keys (option names) and values ("on"
  # or "off"). The subsequent expansion# with (j: :) flag joins all elements
  # together separated by spaces. __fzf_completion_options ends up with a value
  # like this: "options=(shwordsplit off aliases on ...)".
  __fzf_completion_options="options=(${(j: :)${(kv)options[@]}})"
else
  # This branch is much slower because it forks to get the names of all
  # zsh options. It's possible to eliminate this fork but it's not worth the
  # trouble because this branch gets taken only on very ancient or broken
  # zsh installations.
  () {
    # That `()` above defines an anonymous function. This is essentially a scope
    # for local parameters. We use it to avoid polluting global scope.
    'local' '__fzf_opt'
    __fzf_completion_options="setopt"
    # `set -o` prints one line for every zsh option. Each line contains option
    # name, some spaces, and then either "on" or "off". We just want option names.
    # Expansion with (@f) flag splits a string into lines. The outer expansion
    # removes spaces and everything that follow them on every line. __fzf_opt
    # ends up iterating over option names: shwordsplit, aliases, etc.
    for __fzf_opt in "${(@)${(@f)$(set -o)}%% *}"; do
      if [[ -o "$__fzf_opt" ]]; then
        # Option $__fzf_opt is currently on, so remember to set it back on.
        __fzf_completion_options+=" -o $__fzf_opt"
      else
        # Option $__fzf_opt is currently off, so remember to set it back off.
        __fzf_completion_options+=" +o $__fzf_opt"
      fi
    done
    # The value of __fzf_completion_options here looks like this:
    # "setopt +o shwordsplit -o aliases ..."
  }
fi

# Enable the default zsh options (those marked with <Z> in `man zshoptions`)
# but without `aliases`. Aliases in functions are expanded when functions are
# defined, so if we disable aliases here, we'll be sure to have no pesky
# aliases in any of our functions. This way we won't need prefix every
# command with `command` or to quote every word to defend against global
# aliases. Note that `aliases` is not the only option that's important to
# control. There are several others that could wreck havoc if they are set
# to values we don't expect. With the following `emulate` command we
# sidestep this issue entirely.
'builtin' 'emulate' 'zsh' && 'builtin' 'setopt' 'no_aliases'

# This brace is the start of try-always block. The `always` part is like
# `finally` in lesser languages. We use it to *always* restore user options.
{
# The 'emulate' command should not be placed inside the interactive if check;
# placing it there fails to disable alias expansion. See #3731.
if [[ -o interactive ]]; then

# To use custom commands instead of find, override _fzf_compgen_{path,dir}
#
#   _fzf_compgen_path() {
#     echo "$1"
#     command find -L "$1" \
#       -name .git -prune -o -name .hg -prune -o -name .svn -prune -o \( -type d -o -type f -o -type l \) \
#       -a -not -path "$1" -print 2> /dev/null | sed 's@^\./@@'
#   }
#
#   _fzf_compgen_dir() {
#     command find -L "$1" \
#       -name .git -prune -o -name .hg -prune -o -name .svn -prune -o -type d \
#       -a -not -path "$1" -print 2> /dev/null | sed 's@^\./@@'
#   }

###########################################################

#----BEGIN INCLUDE common.sh
# NOTE: Do not directly edit this section, which is copied from "common.sh".
# To modify it, one can edit "common.sh" and run "./update.sh" to apply
# the changes. See code comments in "common.sh" for the implementation details.

__fzf_defaults() {
  printf '%s\n' "--height ${FZF_TMUX_HEIGHT:-40%} --min-height 20+ --bind=ctrl-z:ignore $1"
  command cat "${FZF_DEFAULT_OPTS_FILE-}" 2> /dev/null
  printf '%s\n' "${FZF_DEFAULT_OPTS-} $2"
}

__fzf_exec_awk() {
  if [[ -z ${__fzf_awk-} ]]; then
    __fzf_awk=awk
    if [[ $OSTYPE == solaris* && -x /usr/xpg4/bin/awk ]]; then
      __fzf_awk=/usr/xpg4/bin/awk
    elif command -v mawk > /dev/null 2>&1; then
      local n x y z d
      IFS=' .' read -r n x y z d <<< $(command mawk -W version 2> /dev/null)
      [[ $n == mawk ]] &&
        (((x * 1000 + y) * 1000 + z >= 1003004)) 2> /dev/null &&
        ((d >= 20230302)) 2> /dev/null &&
        __fzf_awk=mawk
    fi
  fi
  LC_ALL=C exec "$__fzf_awk" "$@"
}
#----END INCLUDE

__fzf_comprun() {
  if [[ "$(type _fzf_comprun 2>&1)" =~ function ]]; then
    _fzf_comprun "$@"
  elif [ -n "${TMUX_PANE-}" ] && { [ "${FZF_TMUX:-0}" != 0 ] || [ -n "${FZF_TMUX_OPTS-}" ]; }; then
    shift
    if [ -n "${FZF_TMUX_OPTS-}" ]; then
      fzf-tmux ${(Q)${(Z+n+)FZF_TMUX_OPTS}} -- "$@"
    else
      fzf-tmux -d ${FZF_TMUX_HEIGHT:-40%} -- "$@"
    fi
  else
    shift
    fzf "$@"
  fi
}

# Extract the name of the command. e.g. ls; foo=1 ssh **<tab>
__fzf_extract_command() {
  # Control completion with the "compstate" parameter, insert and list nothing
  compstate[insert]=
  compstate[list]=
  cmd_word="${(Q)words[1]}"
}

__fzf_generic_path_completion() {
  local base lbuf compgen fzf_opts suffix tail dir leftover matches
  base=$1
  lbuf=$2
  compgen=$3
  fzf_opts=$4
  suffix=$5
  tail=$6

  setopt localoptions nonomatch
  if [[ $base = *'$('* ]] || [[ $base = *'<('* ]] || [[ $base = *'>('* ]] || [[ $base = *':='* ]] || [[ $base = *'`'* ]]; then
    return
  fi
  eval "base=$base" 2> /dev/null || return
  [[ $base = *"/"* ]] && dir="$base"
  while [ 1 ]; do
    if [[ -z "$dir" || -d ${dir} ]]; then
      leftover=${base/#"$dir"}
      leftover=${leftover/#\/}
      [ -z "$dir" ] && dir='.'
      [ "$dir" != "/" ] && dir="${dir/%\//}"
      matches=$(
        export FZF_DEFAULT_OPTS
        FZF_DEFAULT_OPTS=$(__fzf_defaults "--reverse --scheme=path" "${FZF_COMPLETION_OPTS-}")
        unset FZF_DEFAULT_COMMAND FZF_DEFAULT_OPTS_FILE
        if declare -f "$compgen" > /dev/null; then
          eval "$compgen $(printf %q "$dir")" | __fzf_comprun "$cmd_word" ${(Q)${(Z+n+)fzf_opts}} -q "$leftover"
        else
          if [[ $compgen =~ dir ]]; then
            walker=dir,follow
            rest=${FZF_COMPLETION_DIR_OPTS-}
          else
            walker=file,dir,follow,hidden
            rest=${FZF_COMPLETION_PATH_OPTS-}
          fi
          __fzf_comprun "$cmd_word" ${(Q)${(Z+n+)fzf_opts}} -q "$leftover" --walker "$walker" --walker-root="$dir" ${(Q)${(Z+n+)rest}} < /dev/tty
        fi | while read -r item; do
          item="${item%$suffix}$suffix"
          echo -n -E "${(q)item} "
        done
      )
      matches=${matches% }
      if [ -n "$matches" ]; then
        LBUFFER="$lbuf$matches$tail"
      fi
      zle reset-prompt
      break
    fi
    dir=$(dirname "$dir")
    dir=${dir%/}/
  done
}

_fzf_path_completion() {
  __fzf_generic_path_completion "$1" "$2" _fzf_compgen_path \
    "-m" "" " "
}

_fzf_dir_completion() {
  __fzf_generic_path_completion "$1" "$2" _fzf_compgen_dir \
    "" "/" ""
}

_fzf_feed_fifo() {
  command rm -f "$1"
  mkfifo "$1"
  cat <&0 > "$1" &|
}

_fzf_complete() {
  setopt localoptions ksh_arrays
  # Split arguments around --
  local args rest str_arg i sep
  args=("$@")
  sep=
  for i in {0..${#args[@]}}; do
    if [[ "${args[$i]-}" = -- ]]; then
      sep=$i
      break
    fi
  done
  if [[ -n "$sep" ]]; then
    str_arg=
    rest=("${args[@]:$((sep + 1)):${#args[@]}}")
    args=("${args[@]:0:$sep}")
  else
    str_arg=$1
    args=()
    shift
    rest=("$@")
  fi

  local fifo lbuf matches post
  fifo="${TMPDIR:-/tmp}/fzf-complete-fifo-$$"
  lbuf=${rest[0]}
  post="${funcstack[1]}_post"
  type $post > /dev/null 2>&1 || post=cat

  _fzf_feed_fifo "$fifo"
  matches=$(
    FZF_DEFAULT_OPTS=$(__fzf_defaults "--reverse" "${FZF_COMPLETION_OPTS-} $str_arg") \
    FZF_DEFAULT_OPTS_FILE='' \
      __fzf_comprun "$cmd_word" "${args[@]}" -q "${(Q)prefix}" < "$fifo" | $post | tr '\n' ' ')
  if [ -n "$matches" ]; then
    LBUFFER="$lbuf$matches"
  fi
  command rm -f "$fifo"
}

# To use custom hostname lists, override __fzf_list_hosts.
# The function is expected to print hostnames, one per line as well as in the
# desired sorting and with any duplicates removed, to standard output.
if ! declare -f __fzf_list_hosts > /dev/null; then
  __fzf_list_hosts() {
    command sort -u \
      <(
        # Note: To make the pathname expansion of "~/.ssh/config.d/*" work
        # properly, we need to adjust the related shell options.  We need to
        # unset "NO_GLOB" (or reset "GLOB"), which disable the pathname
        # expansion totally.  We need to unset "DOT_GLOB" and set "CASE_GLOB"
        # to avoid matching unwanted files.  We need to set "NULL_GLOB" to
        # avoid attempting to read the literal filename '~/.ssh/config.d/*'
        # when no matching is found.
        setopt GLOB NO_DOT_GLOB CASE_GLOB NO_NOMATCH NULL_GLOB

        __fzf_exec_awk '
          # Note: mawk <= 1.3.3-20090705 does not support the POSIX brackets of
          # the form [[:blank:]], and Ubuntu 18.04 LTS still uses this
          # 16-year-old mawk unfortunately.  We need to use [ \t] instead.
          match(tolower($0), /^[ \t]*host(name)?[ \t]*[ \t=]/) {
            $0 = substr($0, RLENGTH + 1) # Remove "Host(name)?=?"
            sub(/#.*/, "")
            for (i = 1; i <= NF; i++)
              if ($i !~ /[*?%]/)
                print $i
          }
        ' ~/.ssh/config ~/.ssh/config.d/* /etc/ssh/ssh_config 2> /dev/null
      ) \
      <(
        __fzf_exec_awk -F ',' '
          match($0, /^[][a-zA-Z0-9.,:-]+/) {
            $0 = substr($0, 1, RLENGTH)
            gsub(/[][]|:[^,]*/, "")
            for (i = 1; i <= NF; i++)
              print $i
          }
        ' ~/.ssh/known_hosts 2> /dev/null
      ) \
      <(
        __fzf_exec_awk '
          {
            sub(/#.*/, "")
            for (i = 2; i <= NF; i++)
              if ($i != "0.0.0.0")
                print $i
          }
        ' /etc/hosts 2> /dev/null
      )
  }
fi

_fzf_complete_telnet() {
  _fzf_complete +m -- "$@" < <(__fzf_list_hosts)
}

# The first and the only argument is the LBUFFER without the current word that contains the trigger.
# The current word without the trigger is in the $prefix variable passed from the caller.
_fzf_complete_ssh() {
  local -a tokens
  tokens=(${(z)1})
  case ${tokens[-1]} in
    -i|-F|-E)
      _fzf_path_completion "$prefix" "$1"
      ;;
    *)
      local user
      [[ $prefix =~ @ ]] && user="${prefix%%@*}@"
      _fzf_complete +m -- "$@" < <(__fzf_list_hosts | __fzf_exec_awk -v user="$user" '{print user $0}')
      ;;
  esac
}

_fzf_complete_export() {
  _fzf_complete -m -- "$@" < <(
    declare -xp | sed 's/=.*//' | sed 's/.* //'
  )
}

_fzf_complete_unset() {
  _fzf_complete -m -- "$@" < <(
    declare -xp | sed 's/=.*//' | sed 's/.* //'
  )
}

_fzf_complete_unalias() {
  _fzf_complete +m -- "$@" < <(
    alias | sed 's/=.*//'
  )
}

_fzf_complete_kill() {
  local transformer
  transformer='
    if [[ $FZF_KEY =~ ctrl|alt|shift ]] && [[ -n $FZF_NTH ]]; then
      nths=( ${FZF_NTH//,/ } )
      new_nths=()
      found=0
      for nth in ${nths[@]}; do
        if [[ $nth = $FZF_CLICK_HEADER_NTH ]]; then
          found=1
        else
          new_nths+=($nth)
        fi
      done
      [[ $found = 0 ]] && new_nths+=($FZF_CLICK_HEADER_NTH)
      new_nths=${new_nths[*]}
      new_nths=${new_nths// /,}
      echo "change-nth($new_nths)+change-prompt($new_nths> )"
    else
      if [[ $FZF_NTH = $FZF_CLICK_HEADER_NTH ]]; then
        echo "change-nth()+change-prompt(> )"
      else
        echo "change-nth($FZF_CLICK_HEADER_NTH)+change-prompt($FZF_CLICK_HEADER_WORD> )"
      fi
    fi
  '
  _fzf_complete -m --header-lines=1 --no-preview --wrap --color fg:dim,nth:regular \
    --bind "click-header:transform:$transformer" -- "$@" < <(
    command ps -eo user,pid,ppid,start,time,command 2> /dev/null ||
      command ps -eo user,pid,ppid,time,args 2> /dev/null || # For BusyBox
      command ps --everyone --full --windows # For cygwin
  )
}

_fzf_complete_kill_post() {
  __fzf_exec_awk '{print $2}'
}

fzf-completion() {
  local tokens prefix trigger tail matches lbuf d_cmds cursor_pos cmd_word
  setopt localoptions noshwordsplit noksh_arrays noposixbuiltins

  # http://zsh.sourceforge.net/FAQ/zshfaq03.html
  # http://zsh.sourceforge.net/Doc/Release/Expansion.html#Parameter-Expansion-Flags
  tokens=(${(z)LBUFFER})
  if [ ${#tokens} -lt 1 ]; then
    zle ${fzf_default_completion:-expand-or-complete}
    return
  fi

  # Explicitly allow for empty trigger.
  trigger=${FZF_COMPLETION_TRIGGER-'**'}
  [[ -z $trigger && ${LBUFFER[-1]} == ' ' ]] && tokens+=("")

  # When the trigger starts with ';', it becomes a separate token
  if [[ ${LBUFFER} = *"${tokens[-2]-}${tokens[-1]}" ]]; then
    tokens[-2]="${tokens[-2]-}${tokens[-1]}"
    tokens=(${tokens[0,-2]})
  fi

  lbuf=$LBUFFER
  tail=${LBUFFER:$(( ${#LBUFFER} - ${#trigger} ))}

  # Trigger sequence given
  if [ ${#tokens} -gt 1 -a "$tail" = "$trigger" ]; then
    d_cmds=(${=FZF_COMPLETION_DIR_COMMANDS-cd pushd rmdir})

    {
      cursor_pos=$CURSOR
      # Move the cursor before the trigger to preserve word array elements when
      # trigger chars like ';' or '`' would otherwise reset the 'words' array.
      CURSOR=$((cursor_pos - ${#trigger} - 1))
      # Check if at least one completion system (old or new) is active.
      # If at least one user-defined completion widget is detected, nothing will
      # be completed if neither the old nor the new completion system is enabled.
      # In such cases, the 'zsh/compctl' module is loaded as a fallback.
      if ! zmodload -F zsh/parameter p:functions 2>/dev/null || ! (( ${+functions[compdef]} )); then
        zmodload -F zsh/compctl 2>/dev/null
      fi
      # Create a completion widget to access the 'words' array (man zshcompwid)
      zle -C __fzf_extract_command .complete-word __fzf_extract_command
      zle __fzf_extract_command
    } always {
      CURSOR=$cursor_pos
      # Delete the completion widget
      zle -D __fzf_extract_command  2>/dev/null
    }

    [ -z "$trigger"      ] && prefix=${tokens[-1]} || prefix=${tokens[-1]:0:-${#trigger}}
    if [[ $prefix = *'$('* ]] || [[ $prefix = *'<('* ]] || [[ $prefix = *'>('* ]] || [[ $prefix = *':='* ]] || [[ $prefix = *'`'* ]]; then
      return
    fi
    [ -n "${tokens[-1]}" ] && lbuf=${lbuf:0:-${#tokens[-1]}}

    if eval "noglob type _fzf_complete_${cmd_word} >/dev/null"; then
      prefix="$prefix" eval _fzf_complete_${cmd_word} ${(q)lbuf}
      zle reset-prompt
    elif [ ${d_cmds[(i)$cmd_word]} -le ${#d_cmds} ]; then
      _fzf_dir_completion "$prefix" "$lbuf"
    else
      _fzf_path_completion "$prefix" "$lbuf"
    fi
  # Fall back to default completion
  else
    zle ${fzf_default_completion:-expand-or-complete}
  fi
}

[ -z "$fzf_default_completion" ] && {
  binding=$(bindkey '^I')
  [[ $binding =~ 'undefined-key' ]] || fzf_default_completion=$binding[(s: :w)2]
  unset binding
}

# Normal widget
zle     -N   fzf-completion
bindkey '^I' fzf-completion
fi

} always {
  # Restore the original options.
  eval $__fzf_completion_options
  'unset' '__fzf_completion_options'
}
### end: completion.zsh ###

function fzf-custom-find() {
  # Enable local options so changes (e.g., shwordsplit) don’t leak outside.
  setopt localoptions

  # Variables to hold start path and recursion depth.
  local s_path level

  # Flag to indicate whether to list only directories.
  local only_dir

  # Parse command-line options: -d (dirs only), -l (max depth), -s (start path).
  while getopts ':dl:s:' opt; do
    case $opt in
    d)
      only_dir=1          # Set flag to restrict output to directories.
      ;;
    l)
      level=$OPTARG       # Store max depth for find's -maxdepth.
      ;;
    s)
      s_path=$OPTARG      # Store starting directory path.
      ;;
    \?)
      # Print error for invalid options and exit silently (caller handles it).
      echo "Invalid option -$OPTARG." >&2
      ;;
    esac
  done

  # Build the base 'find' command with common exclusions and directory printing.
  local cmd="command find -L ${s_path:-.} -mindepth 1 ${level:+-maxdepth $level} \
  \\( -path '*/\\.git' \
  -o -path '*/venv' \
  -o -fstype 'sysfs' \
  -o -fstype 'devfs' \
  -o -fstype 'devtmpfs' \
  -o -fstype 'proc' \\) -prune \
  -o -type d -print"

  # If not 'only_dir', also include regular files and symlinks.
  if [[ -z $only_dir ]]; then
      cmd="$cmd -o -type f -print -o -type l -print"
  fi

  # Suppress 'find' errors (e.g., permission denied) to avoid noise.
  cmd="$cmd 2>/dev/null"

  # If searching from current dir ('.' or unset), strip leading './' from paths.
  if [[ -z $s_path || $s_path == '.' ]]; then
      cmd="$cmd | cut -b3-" # Remove first two characters ('./') from each line.
  fi

  # Default fzf options: height, reverse order, multi-select, preview window, etc.
  local fzf_opts="--height=50% --reverse -m --tiebreak=end \
  --preview-window=right:60%:wrap \
  --bind=ctrl-alt-u:preview-up,ctrl-alt-e:preview-down"

  # Preview command: show content or structure based on file type.
  local fzf_preview_cmd='
    # Resolve symlink if needed; fall back to original path.
    t=${$(readlink {}):-{}}
    # Check if it is a directory (using file -i for MIME type).
    if [[ $(file -i $t) =~ directory ]]; then
      # Use exa/tree to show tree view; fallback to plain message.
      (exa --color=always -T -L 1 {} ||
        tree -C -L 1 {} ||
        echo {} is a directory.) 2>/dev/null
    # Check if binary (non-text).
    elif [[ $(file -i $t) =~ binary ]]; then
      echo {} is a binary file.
    else
      # Use ccat for syntax-highlighted text preview.
      ccat --color=always {} 2>/dev/null
    fi
  '

  # Array to capture exit statuses of pipeline stages.
  local -a ret_array

  # Default success exit code.
  local ret=0

  # Execute the full pipeline:
  eval $cmd | \
  # Pass paths to fzf with preview and extra options (from caller).
  fzf ${(z)fzf_opts} --preview $fzf_preview_cmd ${(z)EXTRA_OPTS} | {
    # Quote each selected item for safe shell insertion (Zsh (q) quoting).
    while read item; do
      printf "${(q)item} "
    done
  } | \
  # Remove trailing space from final output line.
  sed -E '$s/ $//'

  # Capture exit statuses of all pipeline components.
  ret_array=($pipestatus)

  # 'find' returns 1 on warnings (e.g., permission denied); treat as success.
  if (( $ret_array[1] == 1 )); then
    ret=0
  fi

  # Propagate any non-zero exit status from fzf or downstream commands.
  local p_ret
  for p_ret in $ret_array[2,-1]; do
    if (( p_ret )); then
      ret=$p_ret
    fi
  done

  # Return final exit status (0 = success, 1 = cancelled, etc.).
  return $ret
}

function fzf-custom-find-widget() {
  # Exit status of the operation (0 = success, 1 = cancelled, 141 = SIGPIPE).
  local ret=0

  # Split the left part of the command line (before cursor) into shell tokens.
  local tokens=(${(z)LBUFFER})

  # Arguments to pass to the external 'fzf-custom-find' command (e.g., -d for
  # dirs only).
  local -a cmd_opts=()

  # Additional options to pass to fzf via environment variable EXTRA_OPTS.
  local -a extra_fzf_opts=()

  # If called with argument 'only_dir', restrict selection to directories.
  if [[ $1 == 'only_dir' ]]; then
      cmd_opts+='-d'          # Tell 'fzf-custom-find' to list only directories.
      extra_fzf_opts+='+m'    # Disable multi-select in fzf (single item only).
  fi

  # Check if there's partial input at the end of LBUFFER (no trailing space).
  if (( $#tokens )) && [[ $LBUFFER[-1] != ' ' ]]; then
    # Flag to track if path starts with '~' (tilde expansion needed later).
    local is_wave=0

    # Expand the last token using Zsh parameter expansion (e.g., ~ → $HOME).
    local dir=${(e)tokens[-1]}

    # Detect if original token started with '~'.
    if [[ $dir[1] == ~* ]]; then
      is_wave=1
    fi

    # Replace leading '~' with $HOME for filesystem operations.
    dir=${dir/#'~'/$HOME}

    # If the expanded path is not a directory, split into base + parent dir.
    local base
    if [[ ! -d $dir ]]; then
      base=$(basename -- $dir)   # Extract filename/partial name.
      dir=$(dirname -- $dir)     # Get parent directory.
    fi

    # Pass the target directory to 'fzf-custom-find' for listing.
    cmd_opts+="-s $dir"

    # Pre-fill fzf search query with the basename (e.g., "conf" from "~/conf").
    extra_fzf_opts+=${base:+--query $base}

    # Invoke external 'fzf-custom-find' script with constructed options.
    match=$(EXTRA_OPTS=${(z)extra_fzf_opts} fzf-custom-find ${(z)cmd_opts})
    ret=$?

    # Handle successful selection or SIGPIPE (e.g., fzf killed by user).
    if (( ret == 0 || ret == 141 )); then
      # Restore '~' if original input used it (for aesthetic consistency).
      if (( is_wave )); then
        match=$(sed "s|^$HOME|~|" <<<"$match")
      fi

      # Reconstruct LBUFFER:
      # - If only one token, replace entire LBUFFER.
      # - Otherwise, replace only the last token.
      if (( $#tokens == 1 )); then
        LBUFFER=$match
      else
        LBUFFER="$tokens[1,-2] $match"
      fi
    fi
  else
    # No partial word: insert fzf result at end of current LBUFFER.
    LBUFFER=$LBUFFER$(EXTRA_OPTS=${(z)extra_fzf_opts} \
      fzf-custom-find ${(z)cmd_opts})
    ret=$?
  fi

  # Redraw the prompt to reflect changes (e.g., new path inserted).
  zle reset-prompt

  # Return the exit status of the fzf/fzf-custom-find operation.
  return $ret
}
# Register the external fzf-custom-find-widget function as a ZLE widget.
zle -N fzf-custom-find-widget

# Define a helper widget to refresh the prompt and run precmd functions.
fzf-custom-redraw-prompt() {
  # Iterate over all functions registered in precmd_functions array.
  local precmd
  for precmd in $precmd_functions; do
    # Execute each precmd hook (e.g., update git status, virtual env info).
    $precmd
  done
  # Force Zsh to redraw the entire command prompt (including RPROMPT).
  zle reset-prompt
}
# Register this helper as a ZLE widget.
zle -N fzf-custom-redraw-prompt

# Define a ZLE widget to interactively change directory using fzf.
fzf-custom-cd-widget() {
  # Split the left part of the command line (before cursor) into shell tokens.
  local tokens=(${(z)LBUFFER})

  # Only activate if command line is empty or has a single word (e.g., "cd" or
  # "~/do").
  if (( $#tokens <= 1 )); then
    # Invoke fzf-custom-find-widget in 'only_dir' mode to list directories only.
    zle fzf-custom-find-widget 'only_dir'

    # After selection, check if LBUFFER contains a valid directory path.
    if [[ -d $LBUFFER ]]; then
      # Change current working directory to the selected path.
      cd $LBUFFER
      # Capture exit status of 'cd' (e.g., 1 if directory doesn't exist).
      local ret=$?
      # Clear the command line after successful cd.
      LBUFFER=
      # Redraw prompt to reflect new directory and run precmd hooks.
      zle fzf-custom-redraw-prompt
      # Return cd's exit status to caller.
      return $ret
    fi
  fi
}
# Register the function as a ZLE widget named 'fzf-custom-cd-widget'.
zle -N fzf-custom-cd-widget

function fzf-custom-history() {
  # Enable pipefail only within this function: if any command in a pipeline
  # fails, the entire pipeline returns a non-zero exit status.
  setopt localoptions pipefail

  # Declare a local variable to store the full line selected by fzf (e.g.,
  # "1234  git status").
  local selected_line

  # Build the history selection pipeline:
  selected_line=$(fc -rl 1 | \
    # fc -rl 1: list all history entries from newest to oldest, with event
    # numbers.
    awk '{
      # Copy the full input line (e.g., "1234  git status") into a variable.
      line = $0

      # Remove the leading history number and whitespace (e.g., "1234  " or 
      # "999* "). The regex matches optional spaces, digits, optional asterisks
      # (for modified commands), and trailing spaces/tabs.
      sub(/^[ \t]*[0-9]+\**[ \t]+/, "", line)

      # If the resulting command is non-empty and has not been seen before,
      # print the original line ($0). This ensures only the *first* (i.e.,
      # newest) occurrence of each unique command is kept.
      if (line != "" && !seen[line]++) {
        print $0
      }
    }' | \
    fzf --height=50% -n2..,.. --tiebreak=index \
        --bind=ctrl-r:toggle-sort \
        --query="$1" +m)

  # Capture fzf's exit status (0 = selection made, 1 = cancelled).
  local ret=$?

  # If the user selected a line, extract and print the event number (first field).
  if [[ -n "$selected_line" ]]; then
    # ${(z)selected_line} splits the line using shell parsing rules (respects
    # quotes), then [1] takes the first token (the history event number).
    print "${${(z)selected_line}[1]}"
  fi
  # Return fzf's original exit status to indicate success or cancellation.
  return $ret
}

# Define a custom ZLE widget for interactive history search using fzf.
fzf-custom-history-widget() {
  # Call the 'fhistory' function (autoloaded from fpath) with current buffer.
  # It returns a history event number (e.g., "1234") or empty if cancelled.
  local num=$(fzf-custom-history $LBUFFER)

  # Capture exit status of fhistory (0 = selected, 1 = cancelled).
  local ret=$?

  # If a valid history number was returned, fetch that command into the line.
  if [[ -n $num ]]; then
    zle vi-fetch-history -n $num # Insert history entry by event number.
  fi

  # Redraw the prompt to clear fzf UI artifacts and update display.
  zle reset-prompt

  # Return the original exit status (for chaining or debugging).
  return $ret
}
# Register the above function as a ZLE widget named 'fzf-custom-history-widget'.
zle -N fzf-custom-history-widget

# FZF_DEFAULT_OPTS: Default options.
#   --bind: option allows you to bind a key or an event to one or more atcions.
#           You can use it to customize key bindings or implement dynamic
#           behaviours. It takes a comma-separated list of binding expressions.
#           Each binding expression is KEY:ACTION or EVENT:ACTION. You can bind
#           actions to multiple keys and event by writing comma-seperated list
#           of keys and events before the colon. e.g. KEY1,KEY2,EVENT1:ACTION.
#     `ctrl+j/k`: navigate down/up
#     `ctrl-space`: multiselect if possible
#     `tab`: accept choice
export FZF_DEFAULT_OPTS="--bind=ctrl-t:top,change:top \
  --bind=ctrl-j:down,ctrl-k:up \
  --bind=ctrl-space:toggle
  --bind=tab:accept"

# FZF_DEFAULT_COMMAND: Default command to use when input is a TTY device.
# !Requirements:
#   `brew install fd`
export FZF_DEFAULT_COMMAND='fd'

# Set the trigger key for fzf tab-completion (e.g., `vim **<TAB>` becomes `\`).
# Now, typing `\` after a command triggers fzf-based completion.
export FZF_COMPLETION_TRIGGER='\'

# Enable fzf inside tmux panes (if running in tmux) for better integration.
export FZF_TMUX=1
# When using tmux, limit fzf window height to 80% of the terminal pane.
export FZF_TMUX_HEIGHT='80%'
