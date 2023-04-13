# CMakeList.txt : CMake project for trurl, include source and define
# project specific logic here.
#
cmake_minimum_required (VERSION 3.8)

# Enable Hot Reload for MSVC compilers if supported.
if (POLICY CMP0141)
  cmake_policy(SET CMP0141 NEW)
  set(CMAKE_MSVC_DEBUG_INFORMATION_FORMAT "$<IF:$<AND:$<C_COMPILER_ID:MSVC>,$<CXX_COMPILER_ID:MSVC>>,$<$<CONFIG:Debug,RelWithDebInfo>:EditAndContinue>,$<$<CONFIG:Debug,RelWithDebInfo>:ProgramDatabase>>")
endif()

# set(CMAKE_VERBOSE_MAKEFILE ON)
set(CMAKE_TOOLCHAIN_FILE $ENV{VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake)
# set(VCPKG_MANIFEST_MODE ON)
set(VCPKG_TARGET_TRIPLET $ENV{VSCMD_ARG_TGT_ARCH}-windows-static-md)
# message(CMAKE_GENERATOR_PLATFORM="$ENV{CMAKE_GENERATOR_PLATFORM}")
# message(CMAKE_VS_PLATFORM_NAME="$ENV{CMAKE_VS_PLATFORM_NAME}")
# message(VSCMD_ARG_TGT_ARCH="$ENV{VSCMD_ARG_TGT_ARCH}")

project ("trurl")

# Add source to this project's executable.
add_executable (trurl "../trurl.c" "../version.h")

if (CMAKE_VERSION VERSION_GREATER 3.12)
  set_property(TARGET trurl PROPERTY CXX_STANDARD 20)
endif()

# TODO: Add tests and install targets if needed.

if(MSVC)
    add_definitions(-D_CRT_SECURE_NO_WARNINGS)
endif()

find_package(CURL CONFIG REQUIRED)
target_link_libraries(trurl PRIVATE CURL::libcurl)
