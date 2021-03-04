#!/bin/bash

repourl=$1
branch=$2
buildcmd=$3
buildbefore=$4

USER=deploy
PASSWD=deploy2020%40Gitea
CURRENT_DIR=`pwd`

repodir=`TMP=${repourl##*/} && echo ${TMP%.*}`-$branch


function gitclone() {
    cd $CURRENT_DIR
    /bin/rm -fr $repodir
    git clone -b $branch http://${USER}:${PASSWD}@${repourl#*//} $repodir
    if [[ "$?" != "0" ]]; then
        exit -1
    fi
    cd $repodir
    echo -e "\n---------------------------------更新日志---------------------------------\n"
    git log -3
    echo -e "\n------------------------------------------------------------------------\n"
    date +'%D %T' > commmit.time
}

function gitpull() {
    cd $CURRENT_DIR/$repodir
    git pull
    if [[ "$?" != "0" ]]; then
        # if git pull failed, then git clone
        gitclone
    else
        echo -e "\n---------------------------------更新日志---------------------------------\n"
        git log --since "`cat commmit.time`"
        echo -e "\n------------------------------------------------------------------------\n"
        date +'%D %T' > commmit.time
    fi
}

function main() {
    if [[ "$SPUG_DEPLOY_TYPE" == "2" ]]; then
        echo "`date '+%D %T'` 回滚操作，跳过构建步骤 ..."
        exit 0
    fi

    if [[ "$SPUG_REQUEST_NAME" =~ ^"部署" ]]; then
        # 构建/出库/构建并部署 都需要先构建
        echo -e "`date '+%D %T'` 部署操作，跳过构建步骤 ...\n"
        exit 0
    fi

    if [[  -d "$repodir" ]]; then
        gitpull
    else
        gitclone
    fi

    echo "`date +'%D %T'` 构建前操作 ..."
    echo ${buildbefore} | awk '{run=$0;system(run)}'

    echo "`date +'%D %T'` 构建 ..."
    echo ${buildcmd} | awk '{run=$0;system(run)}'
}

main
