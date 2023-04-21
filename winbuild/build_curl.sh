#!/usr/bin/env bash
GITHUB_WORKSPACE=$(dirname "$(realpath "$0")")
cd "$GITHUB_WORKSPACE"

# variables that go in the matrix section
#DEBUG="no"
ENABLE_UNICODE="yes"
#presets=("x64-debug" "x64-release" "x86-debug" "x86-release")
presets=("x64-debug" "x64-release")

# access with ex:
# ${{matrix.DEBUG}}
# ${{matrix.ENABLE_UNICODE}}

# variables that go in the env section
CURL_VER="8.0.1"
CURL_URL="https://github.com/curl/curl/releases/download/curl-8_0_1/curl-8.0.1.tar.gz"

# access with ex:
# ${env:CURL_VER}
# ${env:CURL_URL}

build_project(){
    preset="$1"
    arr=(${preset//-/ })
    build_arch="${arr[0]}"
    if [ "${arr[1]}" == "debug" ];then
        #build_type="Debug"
        DEBUG="yes"
    else
        #build_type="Release"
        DEBUG="no"
    fi
    #echo "${preset}"
    #echo "${build_arch}"
    #echo "${build_type}"
    
    cd "$GITHUB_WORKSPACE"
    
    if [ ! -d "$GITHUB_WORKSPACE/out" ];then mkdir out;fi
    cd out
    
    # clean up previous output files
    if [ -d "curl-$CURL_VER" ];then rm -rf "curl-$CURL_VER";fi
    # if [ -f "curl-$CURL_VER.tar.gz" ];then rm -f "curl-$CURL_VER.tar.gz";fi
    if [ -d "curl/$preset" ];then rm -rf "curl/$preset";fi

    # download a release version of curl
    # note: the git repo does not build release versions unless modifications are made to include/curl/curlver.h
    if [ ! -f "curl-$CURL_VER.tar.gz" ];then
        curl -LOsSf --retry 6 --retry-connrefused --max-time 999 "$CURL_URL"
    fi
    tar -xzf curl-$CURL_VER.tar.gz
    cd curl-$CURL_VER
    
    # build curl as a static library
    
    # todo: build curl as a static library
    if [ "${arr[1]}" == "debug" ];then
        ./configure --disable-shared \
            --prefix="$GITHUB_WORKSPACE/out/curl/$preset" \
            --with-openssl \
            --enable-debug 
    else
        ./configure --disable-shared \
            --prefix="$GITHUB_WORKSPACE/out/curl/$preset" \
            --with-openssl
    fi
    make
    make install
    "$GITHUB_WORKSPACE/out/curl/$preset/bin/curl" -V
    
    echo ""
}

for preset in "${presets[@]}";do
    build_project "${preset}"
done

echo "Done."
exit
