#!/bin/bash

function egrep_sth() {
    egrep  ".{0,$2}$1.{0,$2}" $3 -Rso  -r --color=always
}

# make
alias m="if [ -f makefile -o -f Makefile ]; then echo 'make'; make; else echo -e '\033[34mmay be no makefile; go building \033[0m'; go build; fi;"
alias cm="make clean; make"
alias cm8="make clean; make -j 8"
alias mc="make clean"
alias m6="make -j6"

# python
alias python="python3"

# vim
alias vi='vim'
alias fullpath='readlink -f'

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
fi

# go
export PATH=$PATH:$GOPATH/bin
export GOPROXY=https://goproxy.io

# autojump
[[ -s ~/.autojump/etc/profile.d/autojump.sh  ]] && source ~/.autojump/etc/profile.d/autojump.sh
