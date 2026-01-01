# https://github.com/zimfw/duration-info

# prompt features: CR before prompt, % escapes, SP marker, and substitution.
setopt nopromptbang prompt{cr,percent,sp,subst}

# Show command duration only if it exceeds 0.5 seconds.
zstyle ':zim:duration-info' threshold 0.5

# Format duration as a 4-digit zero-padded integer followed by " s".
zstyle ':zim:duration-info' format '%.4d s'

# Load the standard Zsh hook management function.
autoload -Uz add-zsh-hook
# Record start time just before a command runs.
add-zsh-hook preexec duration-info-preexec
# Calculate and set duration just before the next prompt appears.
add-zsh-hook precmd duration-info-precmd

# Display command duration (if any) on the right side of the prompt.
RPS1='${duration_info}%'
