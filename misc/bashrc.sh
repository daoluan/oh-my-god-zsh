echo "set completion-ignore-case On" >> ~/.inputrc

cat << 'EOF' > ~/.mybashrc

# script begin
alias l='ls -Alrt'
alias ll='ls -Alrt'
alias jp='json_pp'
alias vi=vim
alias w1='watch -c -n1'
alias w3='watch -c -n3'
# alias p='ps -ef|grep -i'
alias c='mpstat 1'
alias s='md5sum'
alias ss='strings'
alias g='grep -i'

printcol() {
    if [ -z "$1" ]; then
        echo "Usage: command | nthcol <column_number>" >&2
        return 1
    fi
    awk "{print \$$1}"
}

function p() {
    ps -ef | grep -i --color=always "$1" | grep -v grep
}

pk() {
    pids=$(ps aux | grep ffmpeg | awk '{print $2}')
    if [ -z "$pids" ]; then
      echo "No ffmpeg processes found. Exiting."
      exit 0
    fi
    echo "Found the following ffmpeg processes:"
    echo "$pids"
    echo "Press Enter to delete all the above processes"
    read
    echo "$pids" | xargs -I {} kill -9 {}
}

findtext() {
    search_pattern="$1"

    if [ -z "$search_pattern" ]; then
        echo "please input search pattern"
        return 1
    fi

    if [ -z "$2" ] || [ ! -d "$2" ]; then
        search_dir="."
    else
        search_dir="$2"
    fi

    grep -nir "$search_pattern" "$search_dir"
}


f() {
    if [ -d "$1" ]; then
        search_dir="$1"
        shift  # 移除第一个参数（目录），保留后续的模糊匹配参数
    else
        echo 'Search current directory'
        search_dir="."  # 如果第一个参数不是目录，默认使用当前目录
    fi

    if [ -z "$1" ]; then
        echo "please input search file pattern"
        return 1
    fi

    find "$search_dir" -iname "*$1*"
}

function lmf() {
    if [ -z "$1" ]; then echo $(ls -t . | head -n 1); return; fi
    echo $1/$(ls -t $1 | head -n 1)
}

function greplmf () {
    grep -i "$1" $(lmf "$2")
}

function taillmf () {
    tail -f  $(lmf "$2")  | grep -i "$1" --color=always --line-buffered
}

function vimlmf() {
   vim $(lmf "$1")
}

function lmfgrep () {
    greplmf   "$1" "$2"
}

function lmftail () {
    taillmf "$1" "$2"
}

function lmfvim() {
   vimlmf "$1"  "$2"
}

function omf() {
    if [ -z "$1" ]; then
        echo $(ls -tr | head -n 1)
    else
        echo "$1/$(ls -tr "$1" | head -n 1)"
    fi
}

function omfgrep () {
    grep -i "$1" $(omf "$2")
}

function omfvim() {
   vim $(omf "$1")
}

function sharelog() {
    echo "ip:"
    ip addr show | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d/ -f1 | head -n1
    echo "logpath: "
    readlink -f "$PWD/$1"

    latest_file=$(ls -t | head -1)
    creation_time=$(stat -c %y "$latest_file")

    date=$(echo $creation_time | cut -d ' ' -f 1)

    startTime="$date 00:00:00"
    endTime="$date 23:59:59"

    current_dir=$(basename "$PWD")
    streamid=$(echo $current_dir | cut -d '_' -f 1)

    url="https://videoc.woa.com/live_v2/room_info/room_transcode?startTime=$(echo $startTime | sed 's/ /%20/g')&endTime=$(echo $endTime | sed 's/ /%20/g')&bizid=&streamid=$streamid"
    echo $url
    echo
}

function findlatest() { find . -type f -mmin -$1; }

function findlatestexec() {
    if [ "$1" == "-h" ]; then
        echo "Usage: findlatestexec <minutes> <command>"
        echo "Finds files modified in the last <minutes> minutes and executes <command> on each file."
        echo ""
        echo "Arguments:"
        echo "  <minutes>   Specify the time range in minutes to search for modified files."
        echo "  <command>   Command to execute on each found file."
        echo ""
        echo "Example:"
        echo "  findlatestexec 60 'echo Found file'"
        return 0
    fi

     find . -type f -mmin -$1 | xargs -I{} sh -c "echo Handling {}; $2"
 }

function findlatestgrep() {
    find . -type f -mmin -$1  -exec ls -lt {} + | sort -k6,8 | awk '{print $NF}' | xargs -I{} sh -c "echo Handling {}; grep \"$2\" {} --color=always"
}

function g30() {
    findlatestgrep 30 "$1"
}

function g60() {
    findlatestgrep 60 "$1"
}

function g2h() {
    findlatestgrep 120 "$1"
}

function g6h() {
    findlatestgrep 360 "$1"
}

function g1d() {
    findlatestgrep 1440 "$1"
}

function find_recent_and_grep() { find . -type f -mmin -30 | xargs grep "$1"; }

function find_range() { find ./ -type f -newermt "$1" ! -newermt "$2"; }

function myupload {
    bin="$1"; (printf "%-128s" $bin; cat $bin) | nc 30.47.8.191 8001; md5sum $bin
}

function mydownload {
    bin=$1; (printf "%-128s" $bin; cat $bin) | nc  30.47.8.191 8998 >> $bin; md5sum $bin
}

EOF


cat << 'EOF' >> ~/.bashrc
if [[ $SUDO_USER == "dylanzheng" || $TST_HACK_BASH_SESSION_NAME == "dylanzheng" || $LOGNAME == "dylanzheng" ]]; then
    source ~/.mybashrc
fi
EOF


echo "set ignorecase" >> ~/.vimrc

source ~/.bashrc
bind -f ~/.inputrc

clear

echo 'Done'

