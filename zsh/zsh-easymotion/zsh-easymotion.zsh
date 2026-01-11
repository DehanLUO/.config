# zsh-easymotion
#
# Original source: https://github.com/hchbaw/zce.zsh/commit/ee71bfa
# Original Author: Takeshi Banse <takebi@laafc.net>
# License: BSD-3
#

################################################################################
# Internal helper function to generate hierarchical key combinations recursively.
#
# This function builds multi-level jump keys (e.g., "ab", "ac", etc.) when the
# number of targets exceeds the number of available single-character keys.
#
# @param[in] _place_var  Name of the variable to update with generated keys.
# @param[in] _base_keys  String of base characters to use for key generation.
# @param[in] ...         Pairs of (prefix_key, count) indicating how many
#                        suffixes to append to each prefix.
################################################################################
_zsh_easymotion_genh_loop_key () {
  # Store the name of the target variable that will hold the final key list.
  local _place_var="$1"; shift
  # Store the string of base characters (e.g., 'abc...') used to form suffixes.
  local _base_keys="$1"; shift
  # Fetch current value of the target variable by indirect expansion (`(P)`).
  local _current_value="${(P)_place_var}"
  # Declare loop variables for prefix and count.
  local _prefix _count

  # Iterate over alternating arguments: each pair is (prefix, count).
  for _prefix _count in "$@"; do
    # Initialise counter `_i` to the number of suffixes needed for this prefix.
    local -i _i=_count
    # Loop while there are still suffixes to generate.
    while (( _i > 0 )); do
      # Append a new tab-separated key: "${prefix}${_base_keys[_i]}"
      # Note: Zsh arrays are 1-indexed; `_base_keys[_i]` picks the i-th char.
      _current_value="${_current_value}	${_prefix}${_base_keys[_i]}"
      # Decrement counter to move to next character in `_base_keys`.
      (( _i-- ))
    done
    # Update the original variable (by name) with the new value, stripping the
    # leading tab introduced by the first concatenation.
    : ${(P)_place_var::=${_current_value#	}}
  done
}

################################################################################
# Recursive dispatcher for generating multi-level motion keys.
#
# Coordinates recursive key generation based on available base keys and target
# count. Delegates actual key construction to _zsh_easymotion_genh_loop_key.
#
# @param[in] _success_callback  Function to call upon completion.
# @param[in] _positions_str     Space-separated list of match positions.
# @param[in] _query_pattern     Pattern used for matching in buffer.
# @param[in] _buffer            Current ZLE buffer content.
# @param[in] _keygen_func       Key generation function (e.g., _zsh_easymotion_genh_loop_key).
# @param[in] _key_chars         Available key characters for labelling.
# @param[in] _remaining         Number of unmatched targets remaining.
# @param[in] _max_per_level     Maximum keys per hierarchy level.
# @param[in] _accumulated_keys  Accumulated keys from prior recursion (tab-separated).
# @param[in] ...                Additional (prefix, count) pairs for recursion.
################################################################################
_zsh_easymotion_genh_loop() {
  # Extract callback function name for later invocation.
  local _success_callback="$1"; shift
  # Store space-separated string of match positions (1-based indices in buffer).
  local _positions_str="$1"; shift
  # Store space-separated string of match positions (1-based indices in buffer).
  local _query_pattern="$1"; shift
  # Store current ZLE buffer content.
  local _buffer="$1"; shift
  # Store name of key-generation helper function.
  local _keygen_func="$1"; shift
  # Store available labelling characters (e.g., 'asdfghjkl').
  local _key_chars="$1"; shift
  # Store how many more targets need keys beyond what’s already assigned.
  local -i _remaining="$1"; shift
  # Store maximum number of keys assignable per level (usually = #_key_chars).
  local -i _max_per_level="$1"; shift
  # Store accumulated keys from previous recursion levels (tab-separated).
  local _accumulated_keys="$1"; shift
  # Convert accumulated keys into an array using tab as delimiter.
  local -a _accum_array; : ${(A)_accum_array::=${(s.	.)_accumulated_keys}}
  # Capture all remaining arguments as (prefix, count) pairs for this level.
  local -a _key_num_pairs; : ${(A)_key_num_pairs::=${(@)@}}

  # Base case: no more targets to assign → finalise and invoke callback.
  if (( _remaining == 0 )); then
    # Initialise empty string to collect newly generated keys.
    local _generated_keys=""
    # Call key generator to produce keys for current (prefix, count) pairs.
    $_keygen_func \
      _generated_keys \
      "$_key_chars" \
      "${_key_num_pairs[@]}"

    # Invoke success callback with:
    # - query pattern,
    # - buffer,
    # - combined key list (new + old, joined by tab),
    # - original positions string.
    $_success_callback \
      "$_query_pattern" \
      "$_buffer" \
      "${_generated_keys#	}${_accumulated_keys:+	}${_accumulated_keys}" \
      "$_positions_str"
    # Propagate exit status of callback.
    return $?
  # First recursion level: no accumulated keys yet.
  elif [[ -z "$_accumulated_keys" ]]; then
    # Generate initial set of keys using provided (prefix, count) pairs.
    $_keygen_func \
      _accumulated_keys \
      "$_key_chars" \
      "${_key_num_pairs[@]}"
    # Recurse with updated accumulated keys, same remaining count.
    _zsh_easymotion_genh_loop \
      "$_success_callback" \
      "$_positions_str" \
      "$_query_pattern" \
      "$_buffer" \
      "$_keygen_func" \
      "$_key_chars" \
      "$_remaining" \
      "$_max_per_level" \
      "$_accumulated_keys"
    # Propagate exit status.
    return $?
  else
    # Recursive case: we have accumulated keys from prior levels.
    # Take the first prefix from the accumulated list to extend.
    local _first_prefix="${_accum_array[1]}"
    # Remove it from the list (shift left).
    shift _accum_array
    # Determine how many new suffixes to attach to `_first_prefix`:
    # either all remaining targets or up to `_max_per_level`.
    local -i _len=$(( _remaining < _max_per_level ? _remaining : _max_per_level ))
    # Compute how many of those will be *new* targets (not just placeholders).
    local -i _sub_count=$(( _len - 1 ))
    # But if remaining ≤ max, assign all as real targets.
    (( _remaining <= _max_per_level )) && _sub_count=$_remaining

    # Recurse with:
    # - reduced remaining count (`_remaining - _sub_count`),
    # - rest of accumulated prefixes (`_accum_array`),
    # - existing (prefix, count) pairs plus new entry for `_first_prefix`.
    _zsh_easymotion_genh_loop \
      "$_success_callback" \
      "$_positions_str" \
      "$_query_pattern" \
      "$_buffer" \
      "$_keygen_func" \
      "$_key_chars" \
      $(( _remaining - _sub_count )) \
      "$_max_per_level" \
      "${(j.	.)_accum_array}" \
      "${_key_num_pairs[@]}" \
      "$_first_prefix" \
      "$_len"
    # Propagate exit status.
    return $?
  fi
}

################################################################################
# Entry point for single-character motion mode.
#
# Scans buffer for matches of a query pattern, then delegates to hierarchical
# key generation if needed.
#
# @param[in] _query_pattern  Regex-like pattern to search for.
# @param[in] _buffer         Current ZLE buffer.
# @param[in] _callback       Success callback function.
# @param[in] _key_chars      Available labelling characters.
################################################################################
_zsh_easymotion_mode1() {
  # Enable safe array indexing (1-based) and extended globbing within this scope.
  setopt localoptions no_ksharrays no_kshzerosubscript extendedglob
  # Extract parameters.
  local _query="$1"; shift
  local _buffer="$1"; shift
  local _callback="$1"; shift
  local _keys="$1"; shift

  # Define a null byte for internal delimiting.
  local _null_char=$'\0'
  # Define a unique escape sequence unlikely to appear in normal text.
  local _escape_ok=$'\e\e '
  # Define a glob pattern matching the escape sequence followed by digits.
  local _escape_pattern=$'\e\e [[:digit:]]##(#e)'

  # Extract match positions using parameter expansion:
  # - Replace every match of `_query` with `_escape_ok<position>\0`
  #   using `(#b)` to capture match start (`mbegin[1]`).
  # - Split result on null bytes (`(0)`).
  # - Filter only items matching `_escape_pattern` (`(M)`)
  local -a _match_positions
  _match_positions=(
    ${(M)${(0)${(S)_buffer//*(#b)($_query)/${_escape_ok}$mbegin[1]$_null_char}}:#${~_escape_pattern}}
  )
  # Strip the `_escape_ok` prefix from each item to leave only position numbers.
  _match_positions=( ${_match_positions#${_escape_ok}} )

  # If no matches found, signal failure.
  if (( $#_match_positions == 0 )); then
    _zsh_easymotion_fail
    return -1
  # If more matches than available keys, initiate hierarchical key assignment.
  elif (( $#_match_positions > $#_keys )); then
    # - positions as space-separated string: "${(j. .)_match_positions}"
    # - key generator function: _zsh_easymotion_genh_loop_key
    # - remaining after first level: $(( $#_match_positions - $#_keys + 1 )) 
    # - max per level = #keys: $#_keys
    # - no accumulated keys yet: ''
    # - dummy prefix for root level: ' '
    # - assign all keys at root: $#_keys
    _zsh_easymotion_genh_loop \
      "$_callback" \
      "${(j. .)_match_positions}" \
      "$_query" \
      "$_buffer" \
      _zsh_easymotion_genh_loop_key \
      "$_keys" \
      $(( $#_match_positions - $#_keys + 1 )) \
      $#_keys \
      '' \
      ' ' \
      $#_keys
  else
    # Fewer matches than keys: assign one key per match at root level.
    # - no remaining after this: 0
    # - only assign as many as needed: $#_match_positions
    _zsh_easymotion_genh_loop \
      "$_callback" \
      "${(j. .)_match_positions}" \
      "$_query" \
      "$_buffer" \
      _zsh_easymotion_genh_loop_key \
      "$_keys" \
      0 \
      $#_keys \
      '' \
      ' ' \
      $#_match_positions
  fi
}

################################################################################
# Wrapper for mode-2 execution with raw parameters.
#
# @param[in] _query_pattern
# @param[in] _buffer
# @param[in] _key_labels     Tab-separated key labels.
# @param[in] _positions      Space-separated target positions.
################################################################################
_zsh_easymotion_mode2() {
  # Simply forward all arguments to the low-level implementation.
  local _query="$1"
  local _buffer="$2"
  local _key_labels="$3"
  local _positions="$4"
  _zsh_easymotion_mode2_raw \
    "$_query" \
    "$_buffer" \
    "$_key_labels" \
    "$_positions" \
    _zsh_easymotion_move_cursor \
    _zsh_easymotion_keyin_loop \
    _zsh_easymotion_keyin_read
}

################################################################################
# Low-level implementation of interactive key selection mode.
#
# Renders labelled positions in buffer and handles user input recursively.
#
# @param[in] _query
# @param[in] _buffer
# @param[in] _key_labels_str
# @param[in] _positions_str
# @param[in] _move_func
# @param[in] _loop_func
# @param[in] _read_func
################################################################################
_zsh_easymotion_mode2_raw() {
  # Enable extended globbing locally.
  setopt localoptions extendedglob
  # Extract parameters.
  local _query="$1"; shift
  local _buffer="$1"; shift
  # Parse tab-separated key labels into array.
  local _key_labels_str="$1"; local -a _key_labels; : ${(A)_key_labels::=${=_key_labels_str}}; shift
  # Parse space-separated positions into array, then sort in descending order (`Oa`)
  # so that replacement during rendering doesn’t shift indices.
  local _positions_str="$1"; local -a _positions; : ${(A)_positions::=${(Oa)=_positions_str}}; shift
  local _move_func="$1"; shift
  local _loop_func="$1"; shift
  local _read_func="$1"; shift

  # Count number of targets.
  local -i _num_targets=$#_positions

  # No targets → fail.
  if (( _num_targets == 0 )); then
    _zsh_easymotion_fail
    return $?
  # Single target → jump immediately.
  elif (( _num_targets == 1 )); then
    $_move_func $_positions[1]
    return $?
  fi

  # Null byte for internal delimiting.
  local _null_char=$'\0'
  # Index starts at last (highest) position due to reverse-sorted `_positions`.
  local -i _index=_num_targets
  # Replace each match of `_query` in buffer with corresponding key label’s
  # first char. Because `_positions` is sorted descending, replacements don’t
  # affect earlier indices.
  local _rendered_buffer="${_buffer//(#m)$_query/${_key_labels[_index--][1]}}"

  # Prepare prompt items: each is "<key><null><position>", for later parsing.
  local -a _prompt_items
  local -i _n=1
  # Replace each tab in `_key_labels_str` with `\0<position>`, then append final
  # item.
  local _prompt_str
  _prompt_str="${_key_labels_str//(#m)$'\t'/${_null_char}$_positions[((_n++))] }"
  _prompt_str+="${_null_char}$_positions[_n]"
  _prompt_items=(${(s. .)_prompt_str})

  # Start interactive key input loop with:
  # - empty current key sequence,
  # - original and rendered buffers,
  # - utility functions,
  # - and parsed prompt items.
  $_loop_func \
    '' \
    "$_buffer" \
    "$_rendered_buffer" \
    "$_move_func" \
    "$_loop_func" \
    "$_read_func" \
    -- \
    "${(s. .)${:-"$_prompt_items"}}"
}

################################################################################
# Signal failure in motion operation.
#
# Returns non-zero exit code to indicate no match or cancellation.
################################################################################
_zsh_easymotion_fail() {
  # Return -1 to indicate failure (non-zero for boolean false in shell).
  return -1
}

################################################################################
# Move ZLE cursor to specified position (1-based).
#
# @param[in] _target_position  Target cursor position (1-indexed).
################################################################################
_zsh_easymotion_move_cursor() {
  # ZLE uses 0-based cursor index; subtract 1 from 1-based position.
  (( CURSOR = $1 - 1 ))
  return 0
}

################################################################################
# Read a single character with visual feedback.
#
# Temporarily modifies terminal display to show prompt without interfering
# with ZLE state.
#
# @param[out] _output_var  Variable to store read character.
# @param[in]  _prompt_str  Prompt string to display.
# @param[in]  _trailing_newline  If "t", ensures clean redraw after prompt.
################################################################################
_zsh_easymotion_read_char() {
  # Capture output variable name.
  local _output_var="$1"
  # Prompt to display.
  local _prompt_str="$2"
  # Optional flag for newline handling.
  local _trailing_newline="${3-}"

  # If requested and POSTDISPLAY doesn’t already end with newline, move cursor
  # down/up to avoid overwriting command line.
  if [[ "$_trailing_newline" == "t" ]] &&
     { [[ -z "${POSTDISPLAY-}" ]] || [[ "${POSTDISPLAY-}" != *$'\n'* ]]; }; then
    echoti cud1 # move cursor down one line
    echoti cuu1 # move cursor up one line
    zle reset-prompt # force prompt redraw
  fi

  echoti sc # Save cursor position.
  echoti cud 1 # Move to next line.
  # Move to column 0 (with fallback if terminfo lacks `hpa`).
  echoti hpa 0 2>/dev/null || echo -n $'\x1b[1G'
  echoti el # Clear to end of line.
  print -Pn "$_prompt_str" # Print prompt without newline.
  read -s -k 1 $_output_var # Read single silent keystroke into `_output_var`.
  local _ret=$? # Capture exit status before restoring screen.
  # Clear line again and restore cursor.
  echoti hpa 0 2>/dev/null || echo -n $'\x1b[1G'
  echoti el
  echoti rc
  # Return original read status.
  return $_ret
}

################################################################################
# Read target key with configurable prompt.
#
# Uses zstyle to allow customisation of prompt appearance.
#
# @param[out] _key_var  Variable to store pressed key.
################################################################################
_zsh_easymotion_keyin_read() {
  local _key_var="$1"
  # Fetch customisable prompt string via zstyle; default if not set.
  local _prompt_str 
  zstyle -s ':zsh-easymotion:*' prompt-key _prompt_str ||
    _prompt_str='%{\e[1;32m%}Target key:%{\e[0m%} '
  # Delegate to low-level reader.
  _zsh_easymotion_read_char "$_key_var" "$_prompt_str"
}

################################################################################
# Initiate interactive key selection loop with styling.
#
# Fetches highlight styles via zstyle and delegates to raw loop.
#
# @param[in] ...  Forwarded to _zsh_easymotion_keyin_loop_raw.
################################################################################
_zsh_easymotion_keyin_loop() {
  # Declare array for ZLE region highlights.
  local -a _region_highlight
  # Fetch colour/style settings via zstyle, with sensible defaults.
  local _highlight_spec _highlight_multi_spec _dim_spec
  # red for single-char keys
  zstyle -s ':zsh-easymotion:*' fg _highlight_spec \
    || _highlight_spec='fg=196,bold' 
  # orange for multi-char keys
  zstyle -s ':zsh-easymotion:*' fg-multi _highlight_multi_spec \
    || _highlight_multi_spec='fg=208,bold' 
  # dim background
  zstyle -s ':zsh-easymotion:*' bg _dim_spec || _dim_spec='fg=black,bold'
  # Delegate to raw implementation with styles.
  _zsh_easymotion_keyin_loop_raw \
    "$@"
}

################################################################################
# Core logic for recursive key input and buffer highlighting.
#
# Manages ZLE region highlights and recursive key accumulation.
#
# @param[in] _current_key_seq
# @param[in] _original_buffer
# @param[in] _new_buffer
# @param[in] _move_func
# @param[in] _loop_func
# @param[in] _read_func
# @param[in] --             Separator (ignored).
# @param[in] ...            Null-delimited key-position pairs.
################################################################################
_zsh_easymotion_keyin_loop_raw() {
  # Enable extended globbing.
  setopt localoptions extendedglob
  # Current accumulated key sequence (e.g., "a", "ab", etc.)
  local _current_key_seq="$1"; shift
  local _original_buffer="$1"; shift
  local _new_buffer="$1"; shift
  local _move_func="$1"; shift
  local _loop_func="$1"; shift
  local _read_func="$1"; shift
  shift  # skip '--' separator

  # Count number of candidate items (key\0position pairs).
  local -i _num_items=$#
  # No candidates → fail.
  if (( _num_items == 0 )); then
    _zsh_easymotion_fail
    return -1
  # One candidate → jump immediately.
  elif (( _num_items == 1 )); then
    _zsh_easymotion_move_cursor ${1#*$'\0'}
    return 0
  fi

  # Declare match variables for globbing.
  local _match _mbegin _mend
  # If no key pressed yet, show full highlighted buffer.
  if [[ -z "$_current_key_seq" ]]; then
    BUFFER="$_new_buffer"
    # Dim entire buffer.
    region_highlight=("0 $#BUFFER $_dim_style")

    # Separate single-char and multi-char keys for different highlighting.
    local -a _single_highlights _multi_highlights
    local _item _key _pos
    for _item in "$@"; do
      _key=${_item%$'\0'*}
      _pos=${_item#*$'\0'}
      if (( $#_key == 1 )); then
        _single_highlights+=("$(( _pos - 1 )) $_pos $_highlight_spec")
      else
        _multi_highlights+=("$(( _pos - 1 )) $_pos $_highlight_multi_spec")
      fi
    done

    # Apply all highlights.
    region_highlight+=(
      ${_single_highlights[@]}
      ${_multi_highlights[@]}
    )
  else
    # Partial key entered: show original buffer with only matching keys revealed.
    BUFFER="$_original_buffer"
    local _item
    # For each candidate starting with current sequence...
    for _item in ${(M)@:#$_current_key_seq*}; do
      local _pos=${_item#*$'\0'}
      local _key_char=${_item%$'\0'*}
      local _char_index=$(( $#_current_key_seq + 1 ))
      # Reveal the next character of the key at its position.
      BUFFER[$_pos]=${_key_char[$_char_index]}
    done
    # Dim entire buffer.
    region_highlight=("0 $#BUFFER $_dim_style")
    # Highlight only positions that match current prefix.
    region_highlight+=(
      ${${${(M)@:#$_current_key_seq*}#*$'\0'}/(#m)[[:digit:]]##/$((MATCH-1)) $MATCH $_highlight_spec}
    )
  fi
  # Redraw ZLE with new highlights.
  zle -R

  # Read next character.
  local _next_char
  if $_read_func _next_char; then
    # Recurse with extended key sequence and filtered candidates.
    _zsh_easymotion_keyin_loop_raw \
      "$_current_key_seq$_next_char" \
      "$_original_buffer" \
      "$_new_buffer" \
      "$_move_func" \
      "$_loop_func" \
      "$_read_func" \
      -- \
      ${(M)@:#$_current_key_seq$_next_char*}
  else
    # Read failed (e.g., Ctrl-C) → cancel.
    _zsh_easymotion_fail
    return -1
  fi
}

################################################################################
# Context manager for easymotion operations.
#
# Saves/restores buffer and cursor, loads terminfo, and provides safe execution.
#
# @param[in] _worker_func  Function to execute within protected context.
################################################################################
_zsh_easymotion_with_context() {
  # Load terminfo capabilities for cursor control.
  zmodload zsh/terminfo 2>/dev/null
  # Enable extended globbing and brace character classes.
  setopt localoptions extendedglob braceccl

  # Save original buffer and cursor position.
  local _orig_buffer="$BUFFER"
  local -i _orig_cursor=$CURSOR
  # Move cursor to end temporarily (to avoid interference).
  (( CURSOR = $#BUFFER ))
  zle -R

  # Declare region_highlight as local to avoid polluting global scope.
  local -a region_highlight
  {
    # Fetch available keys via zstyle, defaulting to a–z and semicolon.
    local _available_keys
    zstyle -s ':zsh-easymotion:*' keys _available_keys ||
      _available_keys=${(j..)$(print {a-z} \;)}
    # Execute worker function with keys; if it fails, restore cursor.
    "$@" "$_available_keys" || (( CURSOR = _orig_cursor ))
  } always {
    # Always restore original buffer and redisplay.
    BUFFER="$_orig_buffer"
    zle redisplay
  }
}

################################################################################
# Read search character with custom prompt.
#
# @param[out] _char_var  Variable to store input character.
################################################################################
_zsh_easymotion_searchin_read() {
  local _char_var="$1"
  local _prompt_str
  # Customisable prompt for initial character input.
  zstyle -s ':zsh-easymotion:*' prompt-char _prompt_str ||
    _prompt_str='%{\e[1;32m%}Search for character:%{\e[0m%} '
  # Use trailing newline mode for cleaner display.
  _zsh_easymotion_read_char "$_char_var" "$_prompt_str" t
}

################################################################################
# Top-level entry for character-triggered motion.
#
# Reads a character and initiates mode-1 processing.
#
# @param[in] _read_func  Function to read trigger character.
################################################################################
_zsh_easymotion_raw() {
  local _trigger_char
  # Read trigger character using provided reader.
  "$1" _trigger_char
  # Only proceed if printable character entered.
  if [[ "$_trigger_char" == [[:print:]] ]]; then
    _zsh_easymotion_mode1_call \
      "$_trigger_char" \
      "$BUFFER" \
      _zsh_easymotion_mode2 \
      "$2"
  fi
}

################################################################################
# Prepare query pattern with case-sensitivity rules.
#
# Supports 'ignorecase', 'smartcase', and literal matching.
#
# @param[in] _char
# @param[in] _buffer
# @param[in] _callback
# @param[in] _keys
################################################################################
_zsh_easymotion_mode1_call() {
  local _char="$1"; shift
  local _buffer="$1"; shift
  local _callback="$1"; shift
  local _keys="$1"; shift

  # Fetch case-matching mode via zstyle.
  local _case_mode
  zstyle -s ':zsh-easymotion:*' search-case _case_mode || _case_mode=default

  local _query
  # Case-insensitive: match both lower and upper forms.
  if [[ "$_case_mode" == ignorecase && "$_char" == [[:lower:][:upper:]] ]]; then
    # Use `(b)` flag for backslash-escaping special regex chars like '['.
    _query="[${(bL)_char}${(bU)_char}]"
  # Smartcase: if input is lowercase, match both cases; else literal.
  elif [[ "$_case_mode" == smartcase && "$_char" == [[:lower:]] ]]; then
    # Literal match: escape special characters only.
    _query="[${(b)_char}${(bU)_char}]"
  else
    _query="${(b)_char}"
  fi

  # Proceed to mode 1 with constructed pattern.
  _zsh_easymotion_mode1 \
    "$_query" \
    "$_buffer" \
    "$_callback" \
    "$_keys"
}

################################################################################
# Public ZLE widget: activate easymotion.
#
# Binds to `zle -N zsh-easymotion` and invoked by user keybinding.
################################################################################
zsh-easymotion() {
  _zsh_easymotion_with_context \
    _zsh_easymotion_raw \
    _zsh_easymotion_searchin_read
}

# Register ZLE widget so it can be bound to keys.
zle -N zsh-easymotion

# Bind to Ctrl-X / in all major keymaps (emacs, vicmd, viins).
bindkey -M emacs '^X/' zsh-easymotion
bindkey -M vicmd '^X/' zsh-easymotion
bindkey -M viins '^X/' zsh-easymotion

# Compilation utilities (for performance)

################################################################################
# Clean compiled files for zsh-easymotion.
#
# @param[in] _dir  Directory to clean (defaults to ~/.zsh/zfunc).
################################################################################
zsh-easymotion-zcompile-clean() {
  local _dir=${1:-~/.config/zsh/zsh-easymotion}
  # Remove main file and any .zwc cache files.
  rm -f ${_dir}/zsh-easymotion{,zwc*(N)}
}

################################################################################
# Generate and zcompile an autoloadable version of this plugin.
#
# @param[in] _source_file   Path to this source file.
# @param[in] _install_dir   Target directory for compiled file.
################################################################################
zsh-easymotion-zcompile() {
  local _source_file=${1:?Please specify the source file itself.}
  local _install_dir=${2:?Please specify the directory for the zcompiled file.}
  setopt localoptions extendedglob no_shwordsplit

  echo "** zcompiling zsh-easymotion in $_install_dir for faster startups..."
  mkdir -p "$_install_dir"
  zsh-easymotion-zcompile-clean "$_install_dir"

  local _output_file="${_install_dir}/zsh-easymotion"
  echo "* writing code $_output_file"
  {
    # List all relevant functions (public and private).
    local - _func
    local -a _all_funcs
    : ${(A)_all_funcs::=${(Mk)functions:#(zsh-easymotion*|_zsh_easymotion_*)}}
    echo "#!zsh"
    echo "# NOTE: Generated from zsh-easymotion.zsh ($_source_file). DO NOT EDIT."
    echo
    # Exclude compilation helpers from output.
    local -a _exclude_patterns; _exclude_patterns=('zsh-easymotion-zcompile*')
    echo "$(functions ${_all_funcs:#${~${(j.|.)_exclude_patterns}}})"
    echo
    # Ensure widget is registered when loaded.
    echo "zsh-easymotion"
  } >| "$_output_file"

  # Skip compilation if disabled.
  if [[ -n "${ZCE_NOZCOMPILE-}" ]]; then
    return
  fi

  # Use zrecompile if available.
  autoload -Uz zrecompile && {
    echo -n "* "; zrecompile -p -R "$_output_file"
  } && {
    zmodload zsh/datetime

    # Touch .zwc file with future timestamp to ensure it’s newer than source.
    # Darwin (macOS) `touch` lacks `--date`, so use `-t YYYYMMDDHHMM.SS`.
    if [[ "$(uname)" == "Darwin" ]]; then
      touch \
        -t "$(strftime "%Y%m%d%H%M.%S" $((EPOCHSECONDS + 10)))" \
        "$_output_file.zwc"
    else
      touch \
        --date="$(strftime "%F %T" $((EPOCHSECONDS + 10)))" \
        "$_output_file.zwc"
    fi

    # Optionally delete intermediate files.
    if [[ -n "${ZCE_ZCOMPILE_NOKEEP-}" ]]; then
      echo "rm -fv $_output_file ${_output_file}.zwc.*" | sh -x
    fi

    echo "** All done."
    echo "** Update your .zshrc to load the compiled file:"

    # Show user-friendly installation instructions.
    local _source_relative="${_source_file/#$HOME/~}"
    local _output_relative="${_output_file/#$HOME/~}"

    cat <<EOT
## Autoload the compiled file (recommended for production)
# Add directory to fpath
fpath+=($(dirname $_output_relative))
# Autoload the compiled file
autoload -w $_output_relative.zwc
# Register as zle widget
zle -N zsh-easymotion
# Bind to a key (e.g., Ctrl-X /)
bindkey -M emacs '^X/' zsh-easymotion
bindkey -M vicmd '^X/' zsh-easymotion
bindkey -M viins '^X/' zsh-easymotion
EOT
  }
}
