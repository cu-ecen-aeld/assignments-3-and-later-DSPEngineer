#!/bin/bash

set -e

_ensure-local-git-cofig() {
    config=$1
    value=$2

    set +e
    cur_value=$(git config --local ${config})
    set -e

    if [ -z "${cur_value}" ]
    then
        # echo "Setting git ${config} to ${value}"
        git config ${config} ${value}
    fi    
}

path_file=$1

_ensure-local-git-cofig "user.name"  "nobody"
_ensure-local-git-cofig "user.email" "nobody@abc.xyz"

git am ${path_file}