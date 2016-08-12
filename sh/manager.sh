#!/bin/bash

############################
#
# Script to init development enviroment
# Author: Chiao <php@html.js.cn>
#
############################

cmd=${1:-help}
lsbin=$(which ls)
pmdir=${0%/sh/*}
rmbin=$(which rm)
vgbin=$(which vagrant)
source $pmdir/sh/include.sh
projectRoot=$(simpleyml "workspace" $pmdir/settings.yml)
gitPrefix=$(simpleyml "gitPrefix" $pmdir/config.yml)
pmbasename=$(simpleyml "manageralias" $pmdir/config.yml)
cd $pmdir

# print repeat string
hr() {
    local c=${1:-=}
    printf "${c}%.0s" {1..44}
    echo ""
}

confirmAction() {
    read -p "Are you sure??? [yN] " iamsure
    [ "$iamsure" != 'y' ] && {
        echo "Aborted."
        exit 1
    }
}

# collect all projects path
allProjectsPath() {
    $lsbin -d ${projectRoot}/*/ 2>/dev/null
}

tryClone() {
    [ ! -d "$projectRoot/$1" ] && {
        git clone "${gitPrefix}${1}.git" $projectRoot/$1
    }
}

tryMkdirLog() {
    [ ! -d "$projectRoot/$1/log" ] && {
        mkdir $projectRoot/$1/log
    }
}

projectsGit() {
    echo -e "${RED}git $1${NC}"
    projects=${2:-$(allProjectsPath)}

    for project in $projects
    do
        project=$(basename $project)
        tryClone $project
        [ -d $projectRoot/$project/.git ] && {
            hr
            echo -e "${YELLOW}$project${NC} (${GREEN}$(git --git-dir=$projectRoot/$project/.git --work-tree=$projectRoot/$project rev-parse --abbrev-ref HEAD)${NC})"
            git --git-dir=$projectRoot/$project/.git --work-tree=$projectRoot/$project $1
        }
        tryMkdirLog $project
    done
}

# parse args for projects used by projectGit
projectsGitArgs() {
    local pos=${2:-2}
    echo $1 | cut -s -d " " -f${pos}-
}

case $cmd in
help)
    pmbasename="${GREEN}${pmbasename}${NC}"
    echo -e "${YELLOW}Try these Commands: ${NC}"
    echo ""
    echo -e "  $pmbasename {start|stop|reload|restart}    "
    echo ""
    echo -e "  $pmbasename pull [projects]                "
    echo ""
    echo -e "  $pmbasename checkout {branch} [projects]   "
    echo ""
    echo -e "  $pmbasename status [projects]              "
    echo ""
    echo -e "  $pmbasename clean [projects]               "
    echo ""
    echo -e "  $pmbasename gitconfig"
    ;;
gitconfig)
    git config --global alias.co checkout
    git config --global alias.br branch
    git config --global alias.st status
    git config --global alias.ci commit
    git config --global alias.cl "clone --recursive"
    git config --global alias.me "merge --no-ff"
    git config --global alias.last "log -1 HEAD"
    git config --global alias.unstage "reset HEAD --"
    git config --global alias.hist "log --pretty=format:\"%h %ad | %s%d [%an]\" --graph --date=short"
    git config --global alias.stoptrack "update-index --assume-unchanged"
    git config --global core.autocrlf true
    git config --global credential.helper wincred
    ;;
update)
    git --git-dir=$pmdir/.git --work-tree=$pmdir status -sb
    git --git-dir=$pmdir/.git --work-tree=$pmdir pull -q
    ;;
pull)
    projectsGit "pull -n" "$(projectsGitArgs "$*")"
    ;;
co|checkout)
    branch=$(echo $*|cut -s -d" " -f2)
    projectsGit "checkout -q $branch" "$(projectsGitArgs "$*" 3)"
    ;;
g|git)
    projectsGit "$2" "$3"
    ;;
st|status)
    projectsGit "status -s" "$(projectsGitArgs "$*")"
    ;;
clean)
    projectsGit "clean -di -e log" "$(projectsGitArgs "$*")"
    ;;
log)
    logfile=$pmdir/logs/php_errors.log
    [ "$2" = "clean" ] && rm -rf $logfile
    [ ! -f $logfile ] && touch $logfile
    tail -f $logfile
    ;;
vg)
    args=$(echo $*|xargs|cut -s -d" " -f2)
    $vgbin $args
    ;;
start)
    $vgbin up
    ;;
stop)
    $vgbin halt
    ;;
reload)
    $vgbin provision --provision-with reload
    ;;
restart)
    $vgbin provision --provision-with restart
    ;;
reset)
    confirmAction
    $vgbin destroy -f
    $rmbin -rf .vagrant
    $vgbin global-status --prune
    git --git-dir=$pmdir/.git --work-tree=$pmdir pull -f
    $vgbin up
    ;;
*)
    $0 help
    ;;
esac

