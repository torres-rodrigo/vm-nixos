# ── Completion ────────────────────────────────────────────────────────────────
fpath=(/run/current-system/sw/share/zsh/site-functions $fpath)
autoload -U compinit && compinit -d "${XDG_CACHE_HOME}/zsh/zcompdump"

# ── Plugins ───────────────────────────────────────────────────────────────────
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
[[ -r "$XDG_CONFIG_HOME/zsh/nix-autosuggestions.zsh" ]] \
    && source "$XDG_CONFIG_HOME/zsh/nix-autosuggestions.zsh"

# ── Fzf ───────────────────────────────────────────────────────────────────────
export FZF_CTRL_T_COMMAND='fd --hidden --follow --exclude .git --no-ignore'
export FZF_CTRL_T_OPTS='--height 69% --preview "[[ -d {} ]] && eza --tree --color=always --icons=always {} || bat --color=always {}"'
export FZF_ALT_C_COMMAND='fd --type directory --hidden --follow --exclude .git --no-ignore'
export FZF_ALT_C_OPTS='--height 69% --preview "eza --tree --color=always --icons=always {}"'
export FZF_CTRL_R_OPTS='--height 69% --bind ctrl-r:toggle-sort'
export FZF_COMPLETION_TRIGGER='**'
export FZF_COMPLETION_DIR_COMMANDS='cd pushd rmdir'
export FZF_COMPLETION_OPTS='--height 69%'

_fzf_compgen_path() {
  fd --hidden --follow --exclude .git --no-ignore . "$1"
}

_fzf_compgen_dir() {
  fd --type directory --hidden --follow --exclude .git --no-ignore . "$1"
}

source <(fzf --zsh)
# Ctrl+R: command history  Ctrl+T: file selector  Alt+C: directory jump

# Completion styling
zstyle ':completion:*' matcher-list \
    'm:{a-zA-Z}={A-Za-z}' \
    'r:|[._-]=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# ── History ───────────────────────────────────────────────────────────────────
HISTSIZE=10000
HISTFILE="$XDG_STATE_HOME/zsh/.zsh_history"
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory sharehistory hist_ignore_space hist_ignore_all_dups \
       hist_save_no_dups hist_find_no_dups numericglobsort

# ── Keybindings ───────────────────────────────────────────────────────────────
bindkey '^y' autosuggest-accept
bindkey '^g' autosuggest-accept
bindkey '^n' history-search-forward
bindkey '^p' history-search-backward
bindkey '^[' undo                       # Ctrl + [ undo
bindkey '^]' redo                       # Ctrl + ] redo
bindkey '^H' backward-kill-word         # Ctrl + H delete word backwards
bindkey '^[[3;5~' kill-word             # Ctrl + Delete delete word forwards
bindkey '\e[1;5D' backward-word         # Ctrl + Left
bindkey '\e[1;5C' forward-word          # Ctrl + Right

clear-line() {
    BUFFER=''
    CURSOR=0
    zle redisplay
}
zle -N clear-line

copy-line() {
    local text="$BUFFER"
    [[ -z "$text" ]] && return 0

    CUTBUFFER="$text"
    if (( $+commands[wl-copy] )); then
        print -rn -- "$text" | wl-copy 2>/dev/null
    fi

    local -a previous_region_highlight=("${region_highlight[@]}")
    region_highlight+=("0 ${#text} standout")
    zle redisplay
    sleep 0.07
    region_highlight=("${previous_region_highlight[@]}")
    zle redisplay
}
zle -N copy-line

bindkey '^[k' clear-line                # Alt+K
bindkey '^[y' copy-line                 # Alt+Y
# Ctrl + a: Go to beginning of prompt
# Ctrl + e: Go to end of prompt
# Ctrl + f: Go forward in prompt
# Ctrl + b: Go backwards in prompt

autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X' edit-command-line          # Ctrl + X vim mode for command line

# ── Environment ───────────────────────────────────────────────────────────────
export EDITOR="nvim"
export SUDO_EDITOR="$EDITOR"
export BAT_THEME=ansi

# ── Prompt ────────────────────────────────────────────────────────────────────
eval "$(starship init zsh)"

# ── Aliases ───────────────────────────────────────────────────────────────────
alias v='nvim'
alias y='yazi'
alias tm='tmux'
alias ld='cd -'
alias lg='lazygit'
alias ls='eza -lha --icons --group-directories-first'
alias lsf='eza -lha --icons --only-files'
alias lsd='eza -lha --icons --only-dirs'
alias tree='eza --tree --icons'
alias config='cd $HOME/.config/'
alias today='date "+%Y-%m-%d"'
alias dat='date "+%Y-%m-%d %H:%M:%S"'

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ..l='cd .. && eza -lha --icons --group-directories-first'
alias ...l='cd ../.. && eza -lha --icons --group-directories-first'
alias ....l='cd ../../.. && eza -lha --icons --group-directories-first'

# ── Git ───────────────────────────────────────────────────────────────────────
alias gf='git fetch'                                             # git fetch
alias gp='git pull'                                              # git pull
alias gup='git reset --hard ORIG_HEAD'                           # git undo pull
alias gfp='git fetch && git pull'                                # git fetch & git pull
ga() {                                                           # git add interactive
    local -a files
    files=("${(@f)$(git status --porcelain | rg "^.[^ }]" | cut -c4- \
        | fzf -m \
              --prompt 'Files  : ' \
              --preview 'if git ls-files --error-unmatch -- {} >/dev/null 2>&1; then git diff --color=always -- {}; else bat --color=always {}; fi' \
              --height=95%)}")
    [[ -n "$files" ]] && git add "${files[@]}"
}
gus() {                                                          # git unstage
    local -a files
    files=("${(@f)$(git status --porcelain | rg "^[AMDRC]" | cut -c4- \
        | fzf -m \
              --prompt 'Files  : ' \
              --header="Ctrl-A: select all" \
              --preview 'git diff --cached --color=always {};' \
              --height=95%)}")
    [[ -n "$files" ]] && git reset HEAD -- "${files[@]}"
}
alias gaa='git add .'                                            # git add all
alias gau='git add -u'                                           # git add updated
alias gap='git add --patch'                                      # git add patch
gc() { [[ $# -eq 0 ]] && git commit || git commit -m "$*"; }     # git commit
alias gca='git commit --amend'                                   # git commit amend
alias guc='git reset HEAD~1 --soft'                              # git undo commit but keep changes
alias guch='git reset HEAD~1 --hard'                             # git undo commit and discard changes
alias gpu='git push'                                             # git push
alias gst='git status -b'                                        # git status
alias gs='git status -b -s'                                      # git status short
alias gl='git log --all --graph --decorate'                      # git log opt -p shows diffs
alias gb='git branch -v'                                         # git branch opt -d and -D for deleting
alias gbr='git branch -v -r'                                     # git branch remote
alias gsb='git switch'                                           # git switch branch
alias gcb='git switch -c'                                        # git create branch
alias gd='git diff --patch-with-stat'                            # git diff
alias gdp='git diff --patch-with-stat --diff-algorithm=patience' # git diff patience
alias gdd='git -c core.pager=delta diff --diff-algorithm=patience' # git delta diff patience
alias gdds='git -c core.pager=delta -c delta.side-by-side=true diff --diff-algorithm=patience' # git delta diff side by side patience
alias gsl='git stash list'                                       # git stash list
gsa() { git stash push -u -m ${*:-WIP $(dat)}; }                 # git stash all message ''
gss() { git stash push --staged -m ${*:-WIP $(dat)}; }           # git stash staged message ''
gsap() { git stash apply "stash@{${1:-0}}"; }                    # git stash apply opt X for specific, latest default
gsd() { git stash drop "stash@{${1:-0}}"; }                      # git stash drop opt X for specific, latest default
alias gr='git restore'                                           # git restore
alias grr='git reset --hard @{u}'                                # git reset to remote
alias grl='git reset --hard HEAD'                                # git reset local
alias gbl="git -c core.pager='delta --color-only' blame -w -C -C -C" # git blame -L <number> or -L <number>,<number>
alias grv='git revert -n'                                        # git revert and stage <commit hashes>
alias grvc='git revert'                                          # git revert and commit <commit hashes>
alias gcl='git clone'                                            # git clone
alias gcls='git clone --depth 1'                                 # git clone shallow -> depth 1

# ── Search functions ──────────────────────────────────────────────────────────
zle_z() { zle -I 2>/dev/null || true; zd; zle reset-prompt; }
zle -N zle_z
bindkey '\e.' zle_z                     # Alt + . directory jump with preview

_fzf_fd() {
    fd --follow --hidden --exclude .git --no-ignore "$@"
}

zd() {
    local parameter=(.)

    [[ -n "$1" && -d "$1" ]] && parameter+=("$1")

    local dir
    dir=$(_fzf_fd --type directory "${parameter[@]}" \
        | fzf --prompt 'Directory  : ' \
              --preview 'eza --tree --color=always --icons=always {};' \
              --height=95%)

    [[ -n "$dir" ]] && cd "$dir" || return
}

zf() {
    local parameter=(.)

    [[ -n "$1" && -d "$1" ]] && parameter+=("$1")

    local file
    file=$(_fzf_fd --type file "${parameter[@]}" \
        | fzf --prompt 'Files  : ' \
              --preview 'bat --color=always {};' \
              --height=95%)

    [[ -n "$file" ]] && cd "${file:h}" || return
}

za() {
    local parameter=(.)

    [[ -n "$1" && -d "$1" ]] && parameter+=("$1")

    local sel
    sel=$(_fzf_fd "${parameter[@]}" \
        | fzf --prompt 'Search  &  : ' \
              --preview '[[ -d {} ]] && eza --tree --color=always --icons=always {} || bat --color=always {}' \
              --height=95%)

    [[ -z "$sel" ]] && return

    [[ -d "$sel" ]] && cd "$sel" || cd "$(dirname "$sel")"
}

vz() {
    if [[ -n "$1" && -f "$1" ]]; then
        v "$@";
        return;
    fi

    local parameter=(.)

    [[ -n "$1" && -d "$1" ]] && parameter+=("$1")

    local -a sel=("${(@f)$(_fzf_fd "${parameter[@]}" \
        | fzf --prompt 'Search  &  : ' \
              --multi \
              --preview '[[ -d {} ]] && eza --tree --color=always --icons=always {} || bat --color=always {}' \
              --height=95%)}")

    [[ -n "$sel" ]] && v "${sel[@]}"
}

# zsh-syntax-highlighting should be loaded after widgets, keybindings, and prompt setup.
[[ -r "$XDG_CONFIG_HOME/zsh/nix-syntax-highlighting.zsh" ]] \
    && source "$XDG_CONFIG_HOME/zsh/nix-syntax-highlighting.zsh"
