#!/bin/bash

Green='\033[0;32m'
Color_Off='\033[0m'

DIR="$( cd "$( dirname "$0" )" && pwd )"
for ef in $(find $DIR/*/ -name 'env.sh');
do
    echo "${Green}sourcing $ef${Color_Off}"
    source $ef
done
