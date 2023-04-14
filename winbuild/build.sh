#!/usr/bin/env bash
basedir=$(dirname "$(realpath "$0")")
cd "${basedir}"

#if ! command -v ninja &> /dev/null;then
#    echo -e "Please install Ninja:\nsudo apt-get install ninja-build"
#    exit 1
#fi

export VCPKG_DISABLE_METRICS=1

if [ -z "$VCPKG_ROOT" ];then
    if [ ! -d "${basedir}/vcpkg" ];then
        git clone https://github.com/microsoft/vcpkg.git
    else
        git -C vcpkg pull
    fi
    export VCPKG_ROOT="${basedir}/vcpkg"
    ./vcpkg/bootstrap-vcpkg.sh
    #pushd vcpkg
    #./vcpkg update
    #popd
fi

build_project(){
    preset="$1"
    arr=(${preset//-/ })
    build_arch="${arr[0]}"
    if [ "${arr[1]}" == "debug" ];then
        build_type="Debug"
    else
        build_type="Release"
    fi
    #echo "${preset}"
    #echo "${build_arch}"
    #echo "${build_type}"
    
    if [ ! -d "${basedir}/out/build/${preset}" ];then
        mkdir -pv "${basedir}/out/build/${preset}"
    fi
    cd "${basedir}/out/build/${preset}"
    # cmake -G "Visual Studio 17 2022" -A %build_arch% ^
    #     -DCMAKE_BINARY_DIR="%basedir%\out\build\%preset%" ^
    #     -DCMAKE_INSTALL_PREFIX="%basedir%\out\install\%preset%" ^
    #     -DCMAKE_WIN32_EXECUTABLE:BOOL=1 .\..\..\..\
    # cmake --build . --config %build_type%
    if [ ! -f "${basedir}/out/build/${preset}/CMakeCache.txt" ];then
        #cmake -G "Ninja" \
        #    -DCMAKE_C_COMPILER:STRING="gcc" \
        #    -DCMAKE_CXX_COMPILER:STRING="g++" \
        #    -DCMAKE_BUILD_TYPE:STRING="${build_type}" \
        #    -DCMAKE_INSTALL_PREFIX:PATH="%basedir%/out/install/${preset}" \
        #    -DCMAKE_MAKE_PROGRAM="ninja" \
        #    "${basedir}"
        cmake \
            -DCMAKE_BUILD_TYPE:STRING="${build_type}" \
            -DCMAKE_INSTALL_PREFIX:PATH="%basedir%/out/install/${preset}" \
            "${basedir}"
    fi
    cmake --build "${basedir}/out/build/${preset}" --clean-first --config ${build_type}
}

#presets=("x64-debug" "x64-release" "x86-debug" "x86-release")
#for preset in "${presets[@]}";do
#    build_project "${preset}"
#done

build_project "x64-debug"
build_project "x64-release"

echo "Done."
exit
