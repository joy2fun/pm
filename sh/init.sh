#!/bin/bash

############################
#
# Script to init development enviroment
# Author: Chiao <php@html.js.cn>
#
############################

initdir=/d/pm
giturl=https://github.com/joy2fun/pm.git
dotrc=~/.bashrc

simpleyml () { # key,file,default
    [ -f "$2" ] && {
        local value=$(sed -ne "/^${1}:/p" $2 2>/dev/null|cut -s -d" " -f2-)
        if [ "$value" != "" ]; then
            echo $value
        else
            echo $3
        fi
    }
}

updateyml () { # key,value,file
    touch $3
    sed -i -r "/^${1}:/d" $3
    echo "${1}: ${2}" >> $3
}

getRequiredBin () { # bin, return/halt
    local bin=$(which --skip-alias $1 2>/dev/null)
    [ "$bin" = "" ] && {
        echo "$1 not found."
        exit 1
    }

    [ "$2" != "" ] && {
        echo $bin
    }
}

workspace=$(simpleyml "workspace" $initdir/settings.yml)

[ ! -d "$workspace" ] && {
    while true
    do
        read -p "Please input your workspace path: (etc: /d/work) " workspace
        [ -d "$workspace" ] && {
            workspace="${workspace:1:1}:${workspace:2}"
            echo "Workspace: $workspace"
            break
        }
    done
}

getRequiredBin git
getRequiredBin vagrant

git=$(getRequiredBin git 1)
vag=$(getRequiredBin vagrant 1)

[ ! -d "$initdir" ] && {
    $git clone $giturl $initdir
    firstBoot=1
}

[ ! -d "$initdir/.git" ] && {
    echo "$initdir is not a git dir."
    exit 1
}

manageralias=$(simpleyml "manageralias" $initdir/config.yml "pm")
echo "CMD: $manageralias"

touch $dotrc

updateyml "workspace" "$workspace" $initdir/settings.yml

sed -i -r "/^alias\s+(vg|${manageralias})=.*$/d" $dotrc
echo "alias vg='vagrant'" >> $dotrc
echo "alias ${manageralias}='${initdir}/sh/manager.sh'" >> $dotrc
