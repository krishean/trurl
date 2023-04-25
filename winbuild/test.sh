#!/usr/bin/env bash
GITHUB_WORKSPACE=$(dirname "$(realpath "$0")")
cd "$GITHUB_WORKSPACE"
#if [ -z "$PYTHON3" ];then PYTHON3="python3";fi
presets=("x64-debug" "x64-release" "x86-debug" "x86-release")
for preset in "${presets[@]}";do
    #if [ -d "$GITHUB_WORKSPACE/out/install/${preset}/bin" ];then
    #    cd "$GITHUB_WORKSPACE/out/install/${preset}/bin"
    if [ -d "$GITHUB_WORKSPACE/out/build/${preset}" ];then
        cd "$GITHUB_WORKSPACE/out/build/${preset}"
        echo "Testing ${preset}..."
        #perl "$GITHUB_WORKSPACE/../test.pl"
        #$PYTHON3 "$GITHUB_WORKSPACE/../test.py"
        ctest -V
    else
        echo " note: The ${preset} directory does not exist."
    fi
done
echo "Done."
exit
