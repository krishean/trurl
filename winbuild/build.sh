#!/usr/bin/env bash
GITHUB_WORKSPACE=$(dirname "$(realpath "$0")")
cd "$GITHUB_WORKSPACE"

#presets=("x64-debug" "x64-release" "x86-debug" "x86-release")
presets=("x64-debug" "x64-release")

#if ! command -v ninja &> /dev/null;then
#    echo -e "Please install Ninja:\nsudo apt-get install ninja-build"
#    exit 1
#fi

#export VCPKG_DISABLE_METRICS=1

#if [ -z "$VCPKG_ROOT" ];then
#    if [ ! -d "$GITHUB_WORKSPACE/vcpkg" ];then
#        git clone https://github.com/microsoft/vcpkg.git
#    else
#        git -C vcpkg pull
#    fi
#    export VCPKG_ROOT="$GITHUB_WORKSPACE/vcpkg"
#    ./vcpkg/bootstrap-vcpkg.sh
    #pushd vcpkg
    #./vcpkg update
    #popd
    #./vcpkg/vcpkg x-update-baseline
#fi

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
    
    if [ -d "$GITHUB_WORKSPACE/out/build/${preset}" ];then
        rm -rf "$GITHUB_WORKSPACE/out/build/${preset}"
    fi
    if [ ! -d "$GITHUB_WORKSPACE/out/build/${preset}" ];then
        mkdir -pv "$GITHUB_WORKSPACE/out/build/${preset}"
    fi
    cd "$GITHUB_WORKSPACE/out/build/${preset}"
    # cmake -G "Visual Studio 17 2022" -A %build_arch% ^
    #     -DCMAKE_BINARY_DIR="%basedir%\out\build\%preset%" ^
    #     -DCMAKE_INSTALL_PREFIX="%basedir%\out\install\%preset%" ^
    #     -DCMAKE_WIN32_EXECUTABLE:BOOL=1 .\..\..\..\
    # cmake --build . --config %build_type%
    if [ ! -f "$GITHUB_WORKSPACE/out/build/${preset}/CMakeCache.txt" ];then
        #cmake -G "Ninja" \
        #    -DCMAKE_C_COMPILER:STRING="gcc" \
        #    -DCMAKE_CXX_COMPILER:STRING="g++" \
        #    -DCMAKE_BUILD_TYPE:STRING="${build_type}" \
        #    -DCMAKE_INSTALL_PREFIX:PATH="%basedir%/out/install/${preset}" \
        #    -DCMAKE_MAKE_PROGRAM="ninja" \
        #    "$GITHUB_WORKSPACE"
        #cmake \
        #    -DCMAKE_BUILD_TYPE:STRING="${build_type}" \
        #    -DCMAKE_INSTALL_PREFIX:PATH="$GITHUB_WORKSPACE/out/install/${preset}" \
        #    -DCMAKE_TOOLCHAIN_FILE:PATH="${VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake" \
        #    -DVCPKG_TARGET_TRIPLET:STRING="${build_arch}-$(uname -s|tr '[A-Z]' '[a-z]')" \
        #    "$GITHUB_WORKSPACE"
        cmake \
            -DCMAKE_BUILD_TYPE:STRING="$build_type" \
            -DCMAKE_BINARY_DIR:PATH="$GITHUB_WORKSPACE/out/build/$preset" \
            -DCMAKE_INSTALL_PREFIX:PATH="$GITHUB_WORKSPACE/out/install/${preset}/bin" \
            -DCURL_INCLUDE_DIR:PATH="$GITHUB_WORKSPACE/out/install/$preset/include" \
            -DCURL_LIBRARY:PATH="$GITHUB_WORKSPACE/out/install/$preset/lib/$curl_lib" \
            "$GITHUB_WORKSPACE"
        #cmake --preset=${preset} "$GITHUB_WORKSPACE"
    fi
    #cmake --build "$GITHUB_WORKSPACE/out/build/${preset}" --clean-first --config ${build_type}
    cmake --build . --clean-first --config $build_type
    # note: when visual studio is used as the generator, you need to specify build_type for the install target
    cmake --build . --target install --config $build_type
    if [ "${build_type}" == "Release" ];then
        strip "$GITHUB_WORKSPACE/out/install/$preset/bin/trurl"
    fi
    "$GITHUB_WORKSPACE/out/install/$preset/bin/trurl" --version
    
    echo ""
}

for preset in "${presets[@]}";do
    build_project "${preset}"
done

echo "Done."
exit
