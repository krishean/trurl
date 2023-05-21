#!/usr/bin/env bash
shopt -s nocasematch
if [ -z "$GITHUB_WORKSPACE" ];then GITHUB_WORKSPACE=$(dirname "$(realpath "$0")");fi
cd "$GITHUB_WORKSPACE"
if [[ $(basename "$PWD") == winbuild ]];then cd ..;fi
if [ "$GITHUB_WORKSPACE" != "$PWD" ];then GITHUB_WORKSPACE="$PWD";fi
#echo "GITHUB_WORKSPACE=$GITHUB_WORKSPACE"

#if [ -z "$PYTHON3" ];then PYTHON3="python3";fi

if [ -n "$2" ];then
    build_arch="$2"
else
    arch="$(uname -m)"
    case $arch in
        
        armv7l)
            build_arch="arm"
            ;;
        
        aarch64 | aarch64_be | armv8b | armv8l)
            build_arch="arm64"
            ;;
        
        x86_64 | amd64)
            build_arch="x64"
            ;;
        
        i686 | i386)
            build_arch="x86"
            ;;
        
        *)
            build_arch="$arch"
            ;;
    esac
fi

if [[ $GITHUB_ACTIONS != true ]];then
    BUILD_CURL_EXE="ON"
else
    # skip building the curl binary under CI to save time, if not
    # building under CI you get a free copy of curl for your trouble
    BUILD_CURL_EXE="OFF"
fi

if [ -n "$3" ];then
    if [[ $3 == debug ]];then
        #DEBUG="yes"
        DEBUG="ON"
    else
        #DEBUG="no"
        DEBUG="OFF"
    fi
else
    #DEBUG="no"
    DEBUG="OFF"
fi

if [ "$DEBUG" == "ON" ];then
    build_type="Debug"
    preset="$build_arch-debug"
    curl_lib="libcurl-d.a"
else
    build_type="Release"
    preset="$build_arch-release"
    curl_lib="libcurl.a"
fi
#echo "build_arch=$build_arch"
#echo "build_type=$build_type"
#echo "preset=$preset"

# variables that go in the matrix section
#DEBUG="no"
#ENABLE_UNICODE="yes"
#presets=("arm64-debug" "arm64-release" "x64-debug" "x64-release" "x86-debug" "x86-release")
#presets=("x64-debug" "x64-release" "x86-debug" "x86-release")
#presets=("x64-debug" "x64-release")

# access with ex:
# ${{matrix.DEBUG}}
# ${{matrix.ENABLE_UNICODE}}

#if ! command -v ninja &> /dev/null;then
#    echo -e "Please install Ninja:\nsudo apt-get install ninja-build"
#    exit 1
#fi

#export VCPKG_DISABLE_METRICS=1

#if [ -z "$VCPKG_ROOT" ];then
#    if [ ! -d "$GITHUB_WORKSPACE/winbuild/vcpkg" ];then
#        git clone https://github.com/microsoft/vcpkg.git
#    else
#        git -C vcpkg pull
#    fi
#    export VCPKG_ROOT="$GITHUB_WORKSPACE/winbuild/vcpkg"
#    ./vcpkg/bootstrap-vcpkg.sh
    #pushd vcpkg
    #./vcpkg update
    #popd
    #./vcpkg/vcpkg x-update-baseline
#fi

# variables that go in the env section
#CURL_VER="8.1.0"
#CURL_URL="https://github.com/curl/curl/releases/download/curl-8_1_0/curl-8.1.0.tar.gz"

if [ -n "$4" ];then
    CURL_VER="$4"
else
    CURL_VER="8.1.0"
fi

# access with ex:
# ${env:CURL_VER}
# ${env:CURL_URL}

CURL_TAG="curl-${CURL_VER//./_}"
CURL_DIR="curl-$CURL_VER"
CURL_TGZ="$CURL_DIR.tar.gz"
CURL_URL="https://github.com/curl/curl/releases/download/$CURL_TAG/$CURL_TGZ"
#echo "CURL_TAG=$CURL_TAG"
#echo "CURL_DIR=$CURL_DIR"
#echo "CURL_TGZ=$CURL_TGZ"
#echo "CURL_URL=$CURL_URL"

# access with ex:
# ${env:CURL_VER}
# ${env:CURL_URL}

build_dir="$GITHUB_WORKSPACE/winbuild/out/build/$preset"
install_dir="$GITHUB_WORKSPACE/winbuild/out/install/$preset"

get_curl(){
    if [ ! -d "$GITHUB_WORKSPACE/winbuild/out" ];then mkdir "$GITHUB_WORKSPACE/winbuild/out";fi
    cd "$GITHUB_WORKSPACE/winbuild/out"
    # clean up previous output files
    #if [ -f "$CURL_TGZ" ];then rm -f "$CURL_TGZ";fi
    #if [ -d "$CURL_DIR" ];then rm -rf "$CURL_DIR";fi
    # download a release version of curl
    # note: the git repo does not build release versions unless modifications are made to include/curl/curlver.h
    if [ ! -f "$CURL_TGZ" ];then
        curl -LOsSf --retry 6 --retry-connrefused --max-time 999 "$CURL_URL"
    fi
    if [ ! -d "$CURL_DIR" ];then
        tar -xzf "$CURL_TGZ"
    fi
    #cd "$CURL_DIR"
}

build_curl(){
    cd "$GITHUB_WORKSPACE/winbuild"
    echo "Building curl $CURL_VER $preset..."
    
    #preset="$1"
    #arr=(${preset//-/ })
    #build_arch="${arr[0]}"
    #if [ "${arr[1]}" == "debug" ];then
    #    build_type="Debug"
    #    #DEBUG="yes"
    #    DEBUG="ON"
    #    curl_lib="libcurl-d.a"
    #else
    #    build_type="Release"
    #    #DEBUG="no"
    #    DEBUG="OFF"
    #    curl_lib="libcurl.a"
    #fi
    #echo "${preset}"
    #echo "${build_arch}"
    #echo "${build_type}"
    
    get_curl
    
    # clean up previous output files
    if [ -d "$build_dir" ];then rm -rf "$build_dir";fi
    if [ ! -d "$build_dir" ];then mkdir -pv "$build_dir";fi
    cd "$build_dir"
    
    # build curl as a static library
    #if [ "${arr[1]}" == "debug" ];then
    #    ./configure --disable-shared \
    #        --prefix="$install_dir" \
    #        --with-openssl \
    #        --enable-debug 
    #else
    #    ./configure --disable-shared \
    #        --prefix="$install_dir" \
    #        --with-openssl
    #fi
    #make
    #make install
    #"$install_dir/bin/curl" -V
    
    # build curl as a static library
    if [ ! -f "$build_dir/CMakeCache.txt" ];then
        # -DCURL_STATIC_CRT=ON
        # note: these build options are roughly equivalent to the
        # microsoft build of curl. trurl does not need the
        # various options enabled as it is only using the parsing
        # engine, building with the options enabled does not hurt
        # anything, but results in a larger executable
        # note: some of these options only affect windows builds
        # but are included here for consistency
        # note: apparently -DCURL_STATIC_CRT=ON will break linux builds?
        cmake \
            -DCMAKE_BUILD_TYPE:STRING="$build_type" \
            -DCMAKE_BINARY_DIR:PATH="$build_dir" \
            -DCMAKE_INSTALL_PREFIX:PATH="$install_dir" \
            -DBUILD_CURL_EXE=$BUILD_CURL_EXE \
            -DBUILD_SHARED_LIBS=OFF \
            -DENABLE_UNICODE=ON \
            -DENABLE_DEBUG=$DEBUG \
            -DCURL_DISABLE_ALTSVC=ON \
            -DCURL_DISABLE_GOPHER=ON \
            -DCURL_DISABLE_LDAP=ON \
            -DCURL_DISABLE_LDAPS=ON \
            -DCURL_DISABLE_MQTT=ON \
            -DCURL_DISABLE_RTSP=ON \
            -DCURL_DISABLE_SMB=ON \
            -DCURL_USE_OPENSSL=ON \
            -DUSE_LIBIDN2=ON \
            "$GITHUB_WORKSPACE/winbuild/out/$CURL_DIR"
    fi
    cmake --build . --clean-first --config $build_type
    # note: when visual studio is used as the generator, you need to specify build_type for the install target
    cmake --build . --target install --config $build_type
    if [[ $GITHUB_ACTIONS != true ]];then
        "$install_dir/bin/curl" --version
    fi
    echo ""
}

check_curl(){
    if [ ! -d "$install_dir/include/curl" ] || [ ! -f "$install_dir/lib/$curl_lib" ];then
        build_curl
    fi
}

build_trurl(){
    cd "$GITHUB_WORKSPACE/winbuild"
    echo "Building trurl $preset..."
    
    #preset="$1"
    #arr=(${preset//-/ })
    #build_arch="${arr[0]}"
    #if [ "${arr[1]}" == "debug" ];then
    #    build_type="Debug"
    #    #DEBUG="yes"
    #    DEBUG="ON"
    #    curl_lib="libcurl-d.a"
    #else
    #    build_type="Release"
    #    #DEBUG="no"
    #    DEBUG="OFF"
    #    curl_lib="libcurl.a"
    #fi
    #echo "${preset}"
    #echo "${build_arch}"
    #echo "${build_type}"
    
    # clean up previous output files
    if [ -d "$build_dir" ];then rm -rf "$build_dir";fi
    if [ ! -d "$build_dir" ];then mkdir -pv "$build_dir";fi
    cd "$build_dir"
    
    # cmake -G "Visual Studio 17 2022" -A $build_arch \
    #     -DCMAKE_BINARY_DIR="$build_dir" \
    #     -DCMAKE_INSTALL_PREFIX="$install_dir" \
    #     -DCMAKE_WIN32_EXECUTABLE:BOOL=1 ./../../../
    # cmake --build . --config $build_type
    if [ ! -f "$build_dir/CMakeCache.txt" ];then
        #cmake -G "Ninja" \
        #    -DCMAKE_C_COMPILER:STRING="gcc" \
        #    -DCMAKE_CXX_COMPILER:STRING="g++" \
        #    -DCMAKE_BUILD_TYPE:STRING="$build_type" \
        #    -DCMAKE_INSTALL_PREFIX:PATH="$install_dir" \
        #    -DCMAKE_MAKE_PROGRAM="ninja" \
        #    "$GITHUB_WORKSPACE/winbuild"
        #cmake \
        #    -DCMAKE_BUILD_TYPE:STRING="${build_type}" \
        #    -DCMAKE_INSTALL_PREFIX:PATH="$install_dir" \
        #    -DCMAKE_TOOLCHAIN_FILE:PATH="$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake" \
        #    -DVCPKG_TARGET_TRIPLET:STRING="$build_arch-$(uname -s|tr '[A-Z]' '[a-z]')" \
        #    "$GITHUB_WORKSPACE/winbuild"
        cmake -DCMAKE_BUILD_TYPE:STRING="$build_type" \
            -DCMAKE_BINARY_DIR:PATH="$build_dir" \
            -DCMAKE_INSTALL_PREFIX:PATH="$install_dir/bin" \
            -DCURL_INCLUDE_DIR:PATH="$install_dir/include" \
            -DCURL_LIBRARY:PATH="$install_dir/lib/$curl_lib" \
            "$GITHUB_WORKSPACE/winbuild"
        #cmake --preset=${preset} "$GITHUB_WORKSPACE/winbuild"
    fi
    #cmake --build "$GITHUB_WORKSPACE/winbuild/out/build/${preset}" --clean-first --config ${build_type}
    cmake --build . --clean-first --config $build_type
    # note: when visual studio is used as the generator, you need to specify build_type for the install target
    cmake --build . --target install --config $build_type
    if [ "${build_type}" == "Release" ];then
        strip "$install_dir/bin/trurl"
    fi
    "$install_dir/bin/trurl" --version
    echo ""
}

verify_trurl(){
    # check for required files in the expected places
    if [ -f "$GITHUB_WORKSPACE/trurl.c" ];then
        if [ -f "$GITHUB_WORKSPACE/version.h" ];then
            if [ -f "$GITHUB_WORKSPACE/winbuild/CMakeLists.txt" ];then
                # we're ready to start building things here
                build_trurl
            else
                echo " error: Required file \"winbuild/CMakeLists.txt\" not found."
            fi
        else
            echo " error: Required file \"version.h\" not found."
        fi
    else
        echo " error: Required file \"trurl.c\" not found."
    fi
}

check_trurl(){
    if [ ! -f "$build_dir/trurl" ];then
        verify_trurl
    fi
}

test_trurl(){
    ret=0
    cd "$GITHUB_WORKSPACE/winbuild"
    echo "Testing trurl $preset..."
    #if [ -d "$install_dir/bin" ];then
    #    cd "$install_dir/bin"
    if [ -d "$build_dir" ];then
        cd "$build_dir"
        # add a link to the testfiles directory so tests work again
        ln -s "$GITHUB_WORKSPACE/testfiles"
        #perl "$GITHUB_WORKSPACE/test.pl"
        #$PYTHON3 "$GITHUB_WORKSPACE/test.py"
        ctest -V
        ret=$?
    else
        echo " note: The $preset directory does not exist."
    fi
    echo ""
    return $ret
}

ret=0

# check $1 for if curl, trurl, test, or clean were specified
if [[ $1 == curl ]];then
    build_curl
elif [[ $1 == trurl ]];then
    # check if curl prerequisite exists for trurl target
    check_curl
    verify_trurl
elif [[ $1 == test ]];then
    check_curl
    # check if trurl prerequisite exists for test target
    check_trurl
    # we're ready to start testing things here
    test_trurl
    ret=$?
elif [[ $1 == clean ]];then
    # clean just removes the out directory
    if [ -d "$GITHUB_WORKSPACE/winbuild/out" ];then
        echo "Removing directory \"winbuild/out\"..."
        rm -rf "$GITHUB_WORKSPACE/winbuild/out"
    else
        echo "Nothing to do..."
    fi
    echo ""
else
    # default is the same as ./build.sh trurl
    check_curl
    verify_trurl
fi

#for preset in "${presets[@]}";do
#    build_curl "${preset}"
#done

#for preset in "${presets[@]}";do
#    build_trurl "${preset}"
#done

#for preset in "${presets[@]}";do
#    test_trurl "${preset}"
#done

echo "Done."
exit $ret
