

##### load Modules
autoload -U colors && colors
setopt transientrprompt
setopt prompt_subst


# User configuration-array in .zshrc
# typeset -a AP_CONFIG_SECS
# AP_CONFIG_SECS+=('prs_user 007 019')               # Username
# AP_CONFIG_SECS+=('prs_host 016 018')               # Hostname
# AP_CONFIG_SECS+=('prs_git 007 019')                # Git
# AP_CONFIG_SECS+=('prs_path 016 018')               # Path
# AP_CONFIG_SECS+=('prs_prompt 000 000')             # Prompt


##### Default configuration-array
typeset -a AP_DEFAULT_SECS
AP_DEFAULT_SECS+=('prs_mode 000 004 000 002')       # VI-Mode
AP_DEFAULT_SECS+=('prs_git 007 019')                # Git
AP_DEFAULT_SECS+=('prs_path 016 018')               # Path
AP_DEFAULT_SECS+=('prs_prompt 007 000')             # Prompt
AP_DEFAULT_SECS+=('prs_host 016 018')               # Hostname
AP_DEFAULT_SECS+=('prs_user 007 019')               # Username
AP_DEFAULT_SECS+=('prs_stat 000 l1')                # Statistics
AP_DEFAULT_SECS+=('prs_error 000 001')              # Error

AP_CONFIG=''
if [[ -v 'AP_CONFIG_SECS' && ${#AP_CONFIG_SECS} -gt 0 ]]; then
    AP_CONFIG='AP_CONFIG_SECS'
else
    AP_CONFIG='AP_DEFAULT_SECS'
fi


##### spezial Characters
SEG_SEP_LEFT="\ue0b0"
SEG_SEP_RIGHT="\ue0b2"
DIAMOND="\u2666"
LIST="\u2261"
UP="\u2b06"
DOWN="\u2b07"
UPDOWN="\u2b0d"
CROSS="\u2717"
PENCIL="\u270e"
FLAG="\u2691"
BRANCH="\ue0a0"


#### Catch the last return
ERROR='0'
precmd_err() { ERROR=$? }
precmd_functions+=( precmd_err )


##### displaying functions

# Editormode
# $1 first forground color
# $2 first background color
# $3 second forground color
# $4 second Background color
function prs_mode () {
    local bgc="$2"
    local str=' I '
    typeset -a ret

    if [[ $KEYMAP == 'vicmd' ]]; then
        bgc="$4"
        str=' N '
    fi

    ret=("$bgc" "%F{$1}$str%f")
    print -l $ret
}


# git-Status
# $1 first forground color
# $2 first background color
prs_git () {
    # return value
    typeset -a ret
    local str

    # branch name
    local bra="$(git symbolic-ref --short --quiet HEAD 2> /dev/null)"

    # if there is a branche name it should be a git repository
    if [ -n "$bra" ]; then

        # is there a remote host?
        if [[ -n $(git config --get remote.origin.url) ]]; then

            # local commits ahead and behind
            local ahead="${$(git log --oneline @{u}.. 2> /dev/null | wc -l)/' '#/}"
            local behind="${$(git log --oneline ..@{u} 2> /dev/null | wc -l)/' '#/}"

            if [[ $ahead -gt 0 ]]; then
                str+="$UP$ahead "
            elif [[ $behind -gt 0 ]]; then
                str+="$DOWN$behind "
            else
                str+="$UPDOWN "
            fi
        fi

        # Number of untracked files
        str+="$CROSS${$(git ls-files --other --exclude-standard 2> /dev/null | wc -l)/' '#/} "

        # number of unstaged modified files
        str+="$PENCIL${$(git ls-files --modified --exclude-standard 2> /dev/null | wc -l)/' '#/} "

        # number of staged modified files
        str+="$FLAG${$(git diff --cached --numstat 2> /dev/null | wc -l)/' '#/} "

        str="%F{$1} $str$BRANCH $bra %f"

    else
        str='-'
    fi

    ret=("$2" "$str")
    print -l $ret
}


# actual path
# $1 first forground color
# $2 first background color
function prs_path() {
    typeset -a ret
    ret=("$2" "%F{$1} %5~ %f")
    print -l $ret
}


# prompt
# $1 first forground color
# $2 first background color
function prs_prompt() {
    typeset -a ret
    ret=("$2" "---")
    print -l $ret
}


# Username
# $1 first forground color
# $2 first background color
function prs_user () {
    typeset -a ret
    local str

    if [[ "$USER" != "$LOGNAME" || -n "$SSH_CONNECTION" ]]; then
        str="%F{$1} $USER %f"
    else
        str='-'
    fi

    ret=("$2" "$str")
    print -l $ret
}


# Hostname
# $1 first forground color
# $2 first background color
function prs_host () {
    typeset -a ret
    local str

    if [[ -n "$SSH_CONNECTION" ]]; then
        str="%F{$1} $(echo "$HOST" | cut -d'.' -f1) %f"
    else
        str='-'
    fi

    ret=("$2" "$str")
    print -l $ret
}


# Some Statistics
# $1 first forground color
# $2 first background color
function prs_stat () {
    typeset -a ret
    local str

    # number of jobs
    str+="%F{$1}$DIAMOND%j%f "

    # number of files
    str+="%F{$1}$LIST${$(ls | wc -l)/' '#/}%f "

    ret=("$2" "$str")
    print -l $ret
}


# Errornumber
# $1 first forground color
# $2 first background color
function prs_error () {
    typeset -a ret
    local str

    # Error
    if [[ "$ERROR" -ne 0 ]]; then
        str+="%F{$1} $ERROR %f"
    else
        str+='-'
    fi

    ret=("$2" "$str")
    print -l $ret
}


##### helping functions #####

# function: build_prs
# build a segmentstring
# $1    backgroundcolor
# $2    next backgroundcolor
# $3    Text in Segment
# $4    side of the segment (left/right)
build_prs () {
    local str=''

    if [[ "$4" == 'left' ]]; then
        str="%K{$1}$3%k%K{$2}%F{$1}$SEG_SEP_LEFT%f%k"
    else
        str="%K{$2}%F{$1}$SEG_SEP_RIGHT%f%k%K{$1}$3%k"
    fi

    echo -n $str
}


# function: get_bgc
# get the background color
# $1    number of the segment
get_bgc () {
    local bgc="${bgcs[$1]}"

    if [[ "${bgc:0:1}" == 'l'  ]]; then
        bgc="${bgcs[${bgc:1:2}]}"
    fi

    echo -n $bgc
}


# register Functions
zle -N zle-line-init
zle -N zle-keymap-select


# call on line-init and keamyp-select
function zle-line-init zle-keymap-select () {
    local strings=()
    local bgcs=()
    local back=()
    local side='left'
    local str=''
    local bgc=''
    local nbgc=''

    # first turn: get string and background to display later
    for config in ${(P)AP_CONFIG}; do

        # take the returned array
        back=("$(${(s. .)config})")

        # first segment to is the actual background color
        bgcs+="${${(f)back}[1]}"

        # second is the string to display
        strings+="${${(f)back}[2]}"
    done

    # second turn: build prompt with cornerstones
    PROMPT=''
    RPROMPT=''

    for (( i = 1; i <= ${#strings}; i++ )); do

        # Get the String
        str="${strings[$i]}"

        # if string marked as empty set it empty
        [[ "$str" == '-' ]] && str=''

        # find the background color
        bgc=$(get_bgc $i)

        # if string marked as prompt change the direction
        if [[ "$str" == '---' ]]; then
            side='right'

        # if not ...
        else

            # ... set prompt string according to the direction based on
            # the next background color
            if [[ $side == 'left' ]]; then
                nbgc=$(get_bgc $i+1)
                PROMPT+=$(build_prs "$bgc" "$nbgc" "$str" "$side")
            else
                nbgc=$(get_bgc $i-1)
                RPROMPT+=$(build_prs "$bgc" "$nbgc" "$str" "$side")
            fi

        fi

    done

    # reset the prompt
    zle reset-prompt
}

