#!/bin/bash

DIR="$( cd "$( dirname "$0" )" && pwd )"
for ef in $(find $DIR/*/ -name 'env.sh');
do
    echo "source $ef"
    source $ef
done
