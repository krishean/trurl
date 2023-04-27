#!/usr/bin/env bash
shopt -s nocasematch
if [ -z "$GITHUB_WORKSPACE" ];then GITHUB_WORKSPACE=$(dirname "$(realpath "$0")");fi
cd "$GITHUB_WORKSPACE"
if [[ $(basename "$PWD") == winbuild ]];then cd ..;fi
if [ "$GITHUB_WORKSPACE" != "$PWD" ];then GITHUB_WORKSPACE="$PWD";fi
#echo "GITHUB_WORKSPACE=$GITHUB_WORKSPACE"

cd "$GITHUB_WORKSPACE/winbuild"
./build.sh clean

exit
