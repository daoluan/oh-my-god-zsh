export LANG=en_US.UTF-8

local ROOTDIR=$(dirname $(dirname "$0"))

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

warning() {
  echo -e $RED$1 $NC
}

succ() {
  echo -e $GREEN$1 $NC
}

# searchtext, text count around searchtext, file
function egrep_sth() {
  if [ "$#" -ne 1 ]; then
    echo "error: $0 searchtext 3 file"
    return
  fi
  egrep ".{0,$2}$1.{0,$2}" $3 -Rso -r --color=always
}

# make
alias m="if [ -f makefile -o -f Makefile ]; then echo 'make'; make; else echo -e '\033[34mmay be no makefile; go building \033[0m'; go build; fi;"
alias cm="make clean; make"
alias cm8="make clean; make -j 8"
alias mc="make clean"
alias m6="make -j6"
alias m8="make -j8"
alias cma="cmake ."

# python
alias python="python3"
srcenv="source .venv/bin/activate"
alias pyenv=$srcenv
alias py="python"
alias pipfreeze="pip3 freeze > requirements.txt"

# vim
alias vi='vim'
alias fullpath='readlink -f'
export EDITOR=vim

# misc
alias cal="cal -B 4 -A 4"
alias c='mpstat 1'
# alias f="find ./ -name"

ft() {
    # 第一个参数为搜索模式
    search_pattern="$1"

    # 检查是否提供了搜索模式
    if [ -z "$search_pattern" ]; then
        echo "请提供要搜索的模式"
        return 1
    fi

    # 如果第二个参数为空或不是目录，默认搜索当前目录
    if [ -z "$2" ] || [ ! -d "$2" ]; then
        search_dir="."
    else
        search_dir="$2"
    fi

    # 使用 grep 进行递归搜索，"$@" 将把其余的参数传递给 grep
    grep -nir "$search_pattern" "$search_dir"
}


f() {
    # 检测第一个参数是否为目录
    if [ -d "$1" ]; then
        search_dir="$1"
        shift  # 移除第一个参数（目录），保留后续的模糊匹配参数
    else
        echo 'Search current directory'
        search_dir="."  # 如果第一个参数不是目录，默认使用当前目录
    fi

    # 检查是否提供了模糊匹配参数
    if [ -z "$1" ]; then
        echo "请提供要模糊匹配的文件名"
        return 1
    fi

    # 使用 find 命令进行模糊匹配
    find "$search_dir" -type f -name "*$1*"
}

r() {
  python x.py
}

# go
# export GOPROXY=https://goproxy.io
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
[[ -s ~/.autojump/etc/profile.d/autojump.sh ]] && source ~/.autojump/etc/profile.d/autojump.sh
autoload -U compinit && compinit -u

# zsh plugins
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#ff00ff,bg=cyan,bold,underline"

# supervisor
if [[ "$(uname)" == "Linux" ]]; then
  # restart
  resu() {
    Color_Off='\033[0m' # Text Reset
    Green='\033[0;32m'  # Green

    processes=$(supervisorctl status | awk '{print $1}' | tr '\n' ' ')
    echo -e ${Green}'which one you want to restart'${Color_Off}
    proarr=($(echo ${processes} | sed 's/ /\n/g'))

    let i=0
    for i in $(seq 0 ${#proarr[@]}); do
      if [[ -z "${proarr[$i]// /}" ]]; then
        continue
      fi

      if [ $# -eq 1 ]; then
        if echo "${proarr[$i]}" | grep "$1" -q >/dev/null; then
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
  cp -f $ROOTDIR/tools/Linux/tig /usr/local/bin/
fi

# git
if command -v tig &>/dev/null; then
  alias ts="tig status"
  alias tc="tig ./"
  alias tl="tig log"
  alias gitdiff="git diff --no-index"
  git config --global alias.st status
  git config --global alias.co checkout
  # if [ ! -e ~/.tigrc ]; then echo 'set ignore-case = yes\nset ignore-space = yes\nset main-view-id-display = yes' >> ~/.tigrc; fi;
fi
git config --global push.default current
# in oh-my-zsh git plugin: https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/git/git.plugin.zsh
# alias gcn!='git commit --verbose --no-edit --amend'
# alias gpf!='git push --force'
alias gcngpf='git status -u no; git commit --verbose --no-edit --amend && git push --force'

# hook cd and auto source pyenv
cd() {
  builtin cd "$@"
  [ -d .venv ] && echo 'source pyenv' && pyenv
}

export PATH=$PATH:$ROOTDIR/tools/$(uname)/bin
export PATH=$PATH:$ROOTDIR/tools/Share/bin

zstyle ':completion:*:(cd|cat|vim|grep|awk|tail|head|md5sum):*' file-sort modification

if ! grep 'hide-status' ~/.gitconfig >/dev/null; then
  echo 'add hide-status in gitconfig'
  git config --global --add oh-my-zsh.hide-status 1
fi

if ! grep 'hide-dirty' ~/.gitconfig >/dev/null; then
  echo 'add hide-dirty gitconfig'
  git config --global --add oh-my-zsh.hide-dirty 1
fi

alias dl='dlogin'

# k8s
alias k='kubectl'

# docker
export DOCKER_DEFAULT_PLATFORM=linux/amd64

export PATH=$PATH:/Users/dylanzheng/code/go/bin

# 一到最后，放到中间无法生效？？？
# macos
if [[ "$(uname)" == "Darwin" ]]; then
  alias sed=gsed
  alias md5sum=md5
  alias m5=md5
  alias ll="ls -altr"
  alias l="ls -altr"
  alias free="top -l 1 -s 0 | grep PhysMem"
  export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles
  alias fullpath='greadlink -f'
  export HOMEBREW_NO_AUTO_UPDATE=1

  ulimit -n 4096
  alias grep=/opt/homebrew/bin/ggrep

  export HOMEBREW_NO_AUTO_UPDATE=1
fi

function sortdiff() {
  diff -c <(sort "$1") <(sort "$2")
}

function onlydiff() {
  diff "${@:3}" <(sort "$1") <(sort "$2")
}

kill_process_by_command() {
  if [ $# -eq 0 ]; then
    echo "Error: No command pattern specified. Usage: kill_process_by_command \"pattern\""
    return 1
  fi

  # $1 是你想要查找和杀死的命令或命令的一部分
  local command_pattern="$1"
  local running_processes=$(ps -ef | grep -iE "$command_pattern" | grep -v grep)

  if [ -n "$running_processes" ]; then
    echo "$running_processes" | awk '{ print $2 }' | xargs -I{} sh -c 'echo killing {}; kill -9 {}'
    if pgrep -f "$command_pattern" >/dev/null; then
      echo "Some processes did not terminate gracefully, sending SIGKILL..."
      kill -9 $pids # 如果还有进程存活，发送 SIGKILL
    fi
  else
    echo "No running process found matching '$command_pattern'"
  fi
}

# tmux
if command -v tmux &>/dev/null; then
  alias tma='tmux a -t'
  alias tmls='tmux ls'
  alias tmnew='tmux new -s'
fi
