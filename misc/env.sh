#!/bin/bash

local ROOTDIR=$( dirname $( dirname "$0" ))

# searchtext, text count around searchtext, file
function egrep_sth() {
    if [ "$#" -ne 1 ]; then
        echo "error: $0 searchtext 3 file"
        return
    fi
    egrep  ".{0,$2}$1.{0,$2}" $3 -Rso  -r --color=always
}

# make
alias m="if [ -f makefile -o -f Makefile ]; then echo 'make'; make; else echo -e '\033[34mmay be no makefile; go building \033[0m'; go build; fi;"
alias cm="make clean; make"
alias cm8="make clean; make -j 8"
alias mc="make clean"
alias m6="make -j6"
alias cma="cmake ."

# python
alias python="python3"
srcenv="source env/bin/activate"
alias pyenv=$srcenv

# vim
alias vi='vim'
alias fullpath='readlink -f'
export EDITOR=vim

r() {
    python x.py
}

# macos
if [[ "$(uname)" == "Darwin" ]]; then
    alias sed=gsed
    alias md5sum=md5
    alias ll="ls -ltr"
    alias l="ls -ltr"
    export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles
    alias fullpath='greadlink -f'
    export HOMEBREW_NO_AUTO_UPDATE=1
fi

# go
export GOPROXY=https://goproxy.io
export GOROOT=/usr/local/go
export GOPATH=$HOME/code/go/
export PATH=$PATH:$GOPATH/bin:$GOROOT/bin:/usr/local/bin/

alias stsu="supervisorctl status"

# other
export LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"

# zsh
ZSH_THEME="ys"

plugins=(
  git
  extract
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

zstyle ':completion:*:(cd|cat|vim|grep|awk|tail|head):*' file-sort modification

# autojump
[[ -s ~/.autojump/etc/profile.d/autojump.sh  ]] && source ~/.autojump/etc/profile.d/autojump.sh
autoload -U compinit && compinit -u

# zsh plugins
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#ff00ff,bg=cyan,bold,underline"

# supervisor
if [[ "$(uname)" == "Linux" ]]; then
    resu () {
        Color_Off='\033[0m'       # Text Reset
        Green='\033[0;32m'        # Green

        processes=$(supervisorctl status|awk '{print $1}'| tr '\n' ' ')
        echo -e ${Green}'which one you want to restart'${Color_Off}
        proarr=(`echo ${processes} | sed 's/ /\n/g'`)

        let i=0
        for i in $(seq 0 ${#proarr[@]})
        do
            if [[ -z "${proarr[$i]// }"  ]]; then
                continue
            fi

            if [ $# -eq 1 ]; then
                if echo "${proarr[$i]}" | grep "$1" -q > /dev/null; then
                    echo $i ${proarr[$i]}
                fi
            else
                echo $i ${proarr[$i]}
            fi
            let i++
        done

        read idx

        printf "staring \e[93m${proarr[$idx]}\033[0m\n"
        echo ${proarr[$i]}
        supervisorctl restart "${proarr[$idx]}"
    }
fi

# git
if command -v tig &> /dev/null
then
    alias ts="tig status"
    alias tc="tig ./"
fi

# hook cd and auto source pyenv
cd() {
   builtin cd "$@"
   [ -d env ] && echo 'source pyenv' && pyenv
}

export PATH=$PATH:$ROOTDIR/tools/$(uname)/bin
export PATH=$PATH:$ROOTDIR/tools/Share/bin

zstyle ':completion:*:(cd|cat|vim|grep|awk|tail|head):*' file-sort modification
