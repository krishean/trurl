# CMakeList.txt : CMake project for trurl, include source and define
# project specific logic here.
#
cmake_minimum_required (VERSION 3.8)

# Enable Hot Reload for MSVC compilers if supported.
if (POLICY CMP0141)
  cmake_policy(SET CMP0141 NEW)
  set(CMAKE_MSVC_DEBUG_INFORMATION_FORMAT "$<IF:$<AND:$<C_COMPILER_ID:MSVC>,$<CXX_COMPILER_ID:MSVC>>,$<$<CONFIG:Debug,RelWithDebInfo>:EditAndContinue>,$<$<CONFIG:Debug,RelWithDebInfo>:ProgramDatabase>>")
endif()

# message(MSVC="${MSVC}")
# message(arch="${arch}")
# set(CMAKE_VERBOSE_MAKEFILE ON)
set(CMAKE_TOOLCHAIN_FILE $ENV{VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake)
# if(NOT CMAKE_BUILD_TYPE STREQUAL "Debug")
#     set(VCPKG_BUILD_TYPE release)
# endif()
# message(CMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE}")
# message(VCPKG_BUILD_TYPE="${VCPKG_BUILD_TYPE}")
# set(VCPKG_MANIFEST_MODE ON)
# if(MSVC)
#     set(VCPKG_TARGET_TRIPLET $ENV{VSCMD_ARG_TGT_ARCH}-windows-static-md)
# endif()
# message(CMAKE_GENERATOR_PLATFORM="$ENV{CMAKE_GENERATOR_PLATFORM}")
# message(CMAKE_VS_PLATFORM_NAME="$ENV{CMAKE_VS_PLATFORM_NAME}")
# message(VSCMD_ARG_TGT_ARCH="$ENV{VSCMD_ARG_TGT_ARCH}")

project ("trurl")

# note: MSVC isn't set until this point, but VCPKG_TARGET_TRIPLET must be set before this point
# message(MSVC="${MSVC}")

# Add source to this project's executable.
add_executable (trurl "../trurl.c" "../version.h")

if (CMAKE_VERSION VERSION_GREATER 3.12)
  set_property(TARGET trurl PROPERTY CXX_STANDARD 20)
endif()

# TODO: Add tests and install targets if needed.

# message(MSVC="${MSVC}")

if(MSVC)
    # this silences a compiler warning about fopen
    add_definitions(-D_CRT_SECURE_NO_WARNINGS)
endif()

find_package(CURL CONFIG REQUIRED)
target_link_libraries(trurl PRIVATE CURL::libcurl)

# run tests in the output directory with ctest -V
enable_testing()
find_package(Perl REQUIRED)
add_test(NAME test COMMAND ${PERL_EXECUTABLE} ${PROJECT_SOURCE_DIR}/../test.pl)
