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
#set(CMAKE_TOOLCHAIN_FILE $ENV{VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake)
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
add_executable(trurl "${PROJECT_SOURCE_DIR}/../trurl.c" "${PROJECT_SOURCE_DIR}/../version.h")

if (CMAKE_VERSION VERSION_GREATER 3.12)
  set_property(TARGET trurl PROPERTY CXX_STANDARD 20)
endif()

# TODO: Add tests and install targets if needed.

# message(MSVC="${MSVC}")

# override msvc's tendency to hide the output executable in yet another subdirectory
# only villains hide the output executable
if(MSVC)
    set_target_properties(${PROJECT_NAME} PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/$<0:>)
    set_target_properties(${PROJECT_NAME} PROPERTIES RUNTIME_OUTPUT_DIRECTORY_DEBUG ${CMAKE_BINARY_DIR}/$<0:>)
    set_target_properties(${PROJECT_NAME} PROPERTIES RUNTIME_OUTPUT_DIRECTORY_RELEASE ${CMAKE_BINARY_DIR}/$<0:>)
endif()

if(MSVC)
    # this silences a compiler warning about fopen
    add_definitions(-D_CRT_SECURE_NO_WARNINGS)
endif()

if(UNIX AND NOT APPLE)
    set(LINUX TRUE)
endif()

# check if using vcpkg
if(CMAKE_TOOLCHAIN_FILE MATCHES "vcpkg\.cmake$" AND VCPKG_TARGET_TRIPLET)
    find_package(CURL CONFIG REQUIRED)
    target_link_libraries(${PROJECT_NAME} PRIVATE CURL::libcurl)
else()
    #find_package(CURL REQUIRED)

    #option(CURL_STATICLIB "Set to ON to build libcurl with static linking."  ON)
    if(WIN32)
        #list(APPEND CURL_LIBS "ws2_32")
        #option(USE_WIN32_IDN "Use WinIDN for IDN support" ON)
        #if(USE_WIN32_IDN)
        #    list(APPEND CURL_LIBS "normaliz")
        #endif()
        # Link required libraries for USE_WIN32_CRYPTO or USE_SCHANNEL
        #if(USE_WIN32_CRYPTO OR USE_SCHANNEL)
        #    list(APPEND CURL_LIBS "advapi32" "crypt32")
        #endif()
        add_definitions("-DCURL_STATICLIB")
    endif()
    #set(CURL_LIBRARY "-lcurl")
    find_package(CURL REQUIRED)
    include_directories(${CURL_INCLUDE_DIR})

    # initialize CURL_LIBS
    set(CURL_LIBS "")

    #if(LIBCURL_ENABLE)
        #target_link_libraries(${PROJECT_NAME} ${CURL_LIBRARIES})
        #target_link_libraries(${PROJECT_NAME} ${CURL_LIBRARIES} ws2_32 wldap32 advapi32 crypt32 Normaliz)
    #endif()

    if(WIN32)
        list(APPEND CURL_LIBS "ws2_32" "wldap32" "advapi32" "crypt32" "normaliz")
    elseif(LINUX)
        find_package(OpenSSL REQUIRED)
        #set(USE_OPENSSL ON)
        if(NOT CMAKE_VERSION VERSION_LESS 3.4)
            list(APPEND CURL_LIBS OpenSSL::SSL OpenSSL::Crypto)
        else()
            list(APPEND CURL_LIBS ${OPENSSL_LIBRARIES})
            #include_directories(${OPENSSL_INCLUDE_DIR})
        endif()
        
        find_package(Threads REQUIRED)
        #set(USE_THREADS_POSIX ${CMAKE_USE_PTHREADS_INIT})
        #set(HAVE_PTHREAD_H ${CMAKE_USE_PTHREADS_INIT})
        set(CURL_LIBS ${CURL_LIBS} ${CMAKE_THREAD_LIBS_INIT})
        
        find_package(ZLIB REQUIRED)
        if(NOT CMAKE_VERSION VERSION_LESS 3.4)
            list(APPEND CURL_LIBS ZLIB::ZLIB)
        else()
            list(APPEND CURL_LIBS ${ZLIB_LIBRARIES})
            #include_directories(${ZLIB_INCLUDE_DIRS})
        endif()
        
        # libldap2-dev is required if libcurl is build with the default options
        # but shouldn't be needed if ldap is disabled in libcurl
        #find_package(Ldap REQUIRED)
        list(APPEND CURL_LIBS "ldap" "lber")
        
        # libidn2-dev is required for IDN support
        list(APPEND CURL_LIBS "idn2")
    endif()
    
    #target_link_libraries(${PROJECT_NAME} ${CURL_LIBRARIES})
    #target_link_libraries(${PROJECT_NAME} PRIVATE CURL::libcurl)
    target_link_libraries(${PROJECT_NAME} PRIVATE CURL::libcurl ${CURL_LIBS})
endif()

install(TARGETS ${PROJECT_NAME} DESTINATION ${CMAKE_INSTALL_PREFIX})
#if(MSVC AND CMAKE_BUILD_TYPE STREQUAL "Debug")
if(MSVC)
    install(FILES $<TARGET_PDB_FILE:${PROJECT_NAME}> DESTINATION ${CMAKE_INSTALL_PREFIX} OPTIONAL)
endif()

# todo: install README.md/COPYING/manpage/other text files?

#find_package(Perl REQUIRED)
#add_test(NAME test.pl COMMAND ${PERL_EXECUTABLE} "${PROJECT_SOURCE_DIR}/../test.pl")
#find_package(Python3)
find_package(Python 3.8 COMPONENTS Interpreter)
#message(Python_VERSION="${Python_VERSION}")
#message(Python_EXECUTABLE="${Python_EXECUTABLE}")
# if python3 was found and the version is high enough, enable tests
if((Python_FOUND) AND (Python_VERSION VERSION_GREATER_EQUAL 3.8))
    # run tests in the output directory with ctest -V
    enable_testing()
    add_test(NAME test.py COMMAND ${Python_EXECUTABLE} -u "${PROJECT_SOURCE_DIR}/../test.py")
else()
    message(STATUS " note: Python 3.8 or higher was not found and is needed for running tests, ctest will not be available")
endif()
