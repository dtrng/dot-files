SCRIPT_PATH="${(%):-%x}"
SCRIPT_DIR="${SCRIPT_PATH:h}"

source $SCRIPT_DIR/antigen.zsh

# Load the oh-my-zsh's library.
antigen use oh-my-zsh

# Bundles from the default repo (robbyrussell's oh-my-zsh).
antigen bundle git
antigen bundle heroku
antigen bundle pip
antigen bundle lein
antigen bundle command-not-found

# Syntax highlighting bundle.
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle zsh-users/zsh-autosuggestions

# Load the theme.
antigen theme robbyrussell

# Tell Antigen that you're done.
antigen apply

source $SCRIPT_DIR/zsh/functions.zsh
source $SCRIPT_DIR/zsh/prompt.zsh
source $SCRIPT_DIR/.aliases
