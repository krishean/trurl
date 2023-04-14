#!/usr/bin/env bash
basedir=$(dirname "$(realpath "$0")")
cd "${basedir}"
presets=("x64-debug" "x64-release" "x86-debug" "x86-release")
for preset in "${presets[@]}";do
    if [ -d "${basedir}/out/build/${preset}" ];then
        cd "${basedir}/out/build/${preset}"
        echo "Testing ${preset}..."
        #perl "${basedir}/../test.pl"
        ctest -V
    else
        echo "Notice: The ${preset} directory does not exist."
    fi
done
echo "Done."
exit
