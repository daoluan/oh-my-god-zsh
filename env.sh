Green='\033[0;32m'
Color_Off='\033[0m'

DIR=$( dirname "$0" )
for ef in $(find $DIR/*/ -name 'env.sh');
do
    echo "${Green}sourcing $ef${Color_Off}"
    source $ef
done

if [[ "$(uname)" == "Darwin" ]]; then
    alias grep="/opt/homebrew/bin/ggrep"
fi

echo "Enjoy!"
