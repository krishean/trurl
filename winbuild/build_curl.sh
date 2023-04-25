#!/usr/bin/env bash
GITHUB_WORKSPACE=$(dirname "$(realpath "$0")")
cd "$GITHUB_WORKSPACE"

# variables that go in the matrix section
#DEBUG="no"
#ENABLE_UNICODE="yes"
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
        build_type="Debug"
        #DEBUG="yes"
        DEBUG="ON"
        curl_lib="libcurl-d.a"
    else
        build_type="Release"
        #DEBUG="no"
        DEBUG="OFF"
        curl_lib="libcurl.a"
    fi
    #echo "${preset}"
    #echo "${build_arch}"
    #echo "${build_type}"
    
    if [ ! -d "$GITHUB_WORKSPACE/out" ];then mkdir "$GITHUB_WORKSPACE/out";fi
    cd "$GITHUB_WORKSPACE/out"
    
    # clean up previous output files
    #if [ -d "curl-$CURL_VER" ];then rm -rf "curl-$CURL_VER";fi
    # if [ -f "curl-$CURL_VER.tar.gz" ];then rm -f "curl-$CURL_VER.tar.gz";fi
    #if [ -d "curl/$preset" ];then rm -rf "curl/$preset";fi
    
    # download a release version of curl
    # note: the git repo does not build release versions unless modifications are made to include/curl/curlver.h
    if [ ! -f "curl-$CURL_VER.tar.gz" ];then
        curl -LOsSf --retry 6 --retry-connrefused --max-time 999 "$CURL_URL"
    fi
    if [ ! -d "curl-$CURL_VER" ];then
        tar -xzf curl-$CURL_VER.tar.gz
    fi
    #cd curl-$CURL_VER
    
    if [ -d "build/$preset" ];then rm -rf "build/$preset";fi
    if [ ! -d "build/$preset" ];then mkdir -pv "build/$preset";fi
    cd "build/$preset"
    
    # build curl as a static library
    #if [ "${arr[1]}" == "debug" ];then
    #    ./configure --disable-shared \
    #        --prefix="$GITHUB_WORKSPACE/out/curl/$preset" \
    #        --with-openssl \
    #        --enable-debug 
    #else
    #    ./configure --disable-shared \
    #        --prefix="$GITHUB_WORKSPACE/out/curl/$preset" \
    #        --with-openssl
    #fi
    #make
    #make install
    #"$GITHUB_WORKSPACE/out/curl/$preset/bin/curl" -V
    
    # build curl as a static library
    if [ ! -f "$GITHUB_WORKSPACE/out/build/$preset/CMakeCache.txt" ];then
        # -DCURL_STATIC_CRT=ON
        # note: these build options are roughly equivalent to the microsoft build of curl
        # trurl does not need the various options enabled as it is only using the parsing engine
        # building with the options enabled does not hurt anything, but results in a larger executable
        cmake \
            -DCMAKE_BUILD_TYPE:STRING="$build_type" \
            -DCMAKE_BINARY_DIR:PATH="$GITHUB_WORKSPACE/out/build/$preset" \
            -DCMAKE_INSTALL_PREFIX:PATH="$GITHUB_WORKSPACE/out/install/$preset" \
            -DBUILD_SHARED_LIBS=OFF \
            -DENABLE_DEBUG=$DEBUG \
            -DCURL_USE_OPENSSL=ON \
            -DUSE_LIBIDN2=ON \
            -DENABLE_UNICODE=ON \
            -DCURL_DISABLE_ALTSVC=ON \
            -DCURL_DISABLE_GOPHER=ON \
            -DCURL_DISABLE_LDAP=ON \
            -DCURL_DISABLE_LDAPS=ON \
            -DCURL_DISABLE_MQTT=ON \
            -DCURL_DISABLE_RTSP=ON \
            -DCURL_DISABLE_SMB=ON \
            "$GITHUB_WORKSPACE/out/curl-8.0.1"
    fi
    cmake --build . --clean-first --config $build_type
    # note: when visual studio is used as the generator, you need to specify build_type for the install target
    cmake --build . --target install --config $build_type
    "$GITHUB_WORKSPACE/out/install/$preset/bin/curl" --version
    
    echo ""
}

for preset in "${presets[@]}";do
    build_project "${preset}"
done

echo "Done."
exit
