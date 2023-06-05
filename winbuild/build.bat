@echo off
rem set "GITHUB_WORKSPACE=%~dp0"
rem cd "%GITHUB_WORKSPACE%"
rem the section below makes the GITHUB_WORKSPACE variable consistent if the
rem batch file is run in github actions or manually run from the winbuild directory
rem set the variable if it is not already set
if "%GITHUB_WORKSPACE%"=="" set "GITHUB_WORKSPACE=%~dp0"
rem strip trailing backslash from path
if "%GITHUB_WORKSPACE:~-1%"=="\" set "GITHUB_WORKSPACE=%GITHUB_WORKSPACE:~0,-1%"
cd "%GITHUB_WORKSPACE%"
rem get the current directory name
for %%a in (.) do set CurrDirName=%%~nxa
rem echo.CurrDirName=%CurrDirName%
rem if we're in the winbuild directory go up one level
if "%CurrDirName%"=="winbuild" cd ..
rem we should be in the right place now
rem echo.cd=%cd%
rem echo.GITHUB_WORKSPACE=%GITHUB_WORKSPACE%
if not "%GITHUB_WORKSPACE%"=="%cd%" set "GITHUB_WORKSPACE=%cd%"
rem echo.GITHUB_WORKSPACE=%GITHUB_WORKSPACE%

rem change underscores to spaces and set the window title
set "window_title=%~n0"
set "window_title=%window_title:_= %"
title %window_title%

rem 2nd argument is the build arch, can be arm64, x64, or x86
if not "%~2"=="" (
    set "Platform=%~2"
)

rem GITHUB_ACTIONS - Always set to true when GitHub Actions is running the
rem workflow. You can use this variable to differentiate when
rem tests are being run locally or by GitHub Actions.
if /I not "%GITHUB_ACTIONS%"=="true" (
    rem call :detect_git
    rem if %errorlevel% NEQ 0 exit /b 1
    rem make sure some version of visual studio is installed
    rem this should be handled by "ilammy/msvc-dev-cmd@v1" in github actions
    call "%GITHUB_WORKSPACE%\winbuild\detect_vs.bat"
    if %errorlevel% NEQ 0 exit /b 1
    rem if /I "%~1"=="test" (
        rem call :detect_perl
        call :detect_python3
        if %errorlevel% NEQ 0 exit /b 1
    rem )
    set "BUILD_CURL_EXE=ON"
) else (
    rem skip building the curl binary under CI to save time, if not
    rem building under CI you get a free copy of curl for your trouble
    set "BUILD_CURL_EXE=OFF"
)
rem set "VCPKG_DISABLE_METRICS=1"
rem note: VCPKG_ROOT needs to be defined
rem if not defined VCPKG_ROOT (
rem     cd "%GITHUB_WORKSPACE%\winbuild"
rem     if not exist "vcpkg" (
rem         git clone https://github.com/microsoft/vcpkg.git
rem     ) else (
rem         git -C vcpkg pull
rem     )
rem     set "VCPKG_ROOT=%GITHUB_WORKSPACE%\winbuild\vcpkg"
rem     call .\vcpkg\bootstrap-vcpkg.bat
rem     .\vcpkg\vcpkg x-update-baseline
rem )

if "%Platform%"=="x86" (
    set "build_arch=Win32"
) else (
    set "build_arch=%Platform%"
)

rem variables that go in the matrix section
rem set "presets=arm64-debug arm64-release x64-debug x64-release x86-debug x86-release"
rem set "presets=x64-debug x64-release x86-debug x86-release"
rem set "presets=x64-release"

rem 3rd argument is build type, either debug or release
if not "%~3"=="" (
    if /I "%~3"=="debug" (
        set "DEBUG=ON"
    ) else (
        set "DEBUG=OFF"
    )
) else (
    set "DEBUG=OFF"
)

if "%DEBUG%"=="ON" (
    set "build_type=Debug"
    set "preset=%Platform%-debug"
    rem set "curl_lib=libcurl_a_debug.lib"
    set "curl_lib=libcurl-d.lib"
) else (
    set "build_type=Release"
    set "preset=%Platform%-release"
    rem set "curl_lib=libcurl_a.lib"
    set "curl_lib=libcurl.lib"
)

rem access with ex:
rem ${{matrix.PRESET}}
rem ${{matrix.BUILD_ARCH}}
rem ${{matrix.BUILD_TYPE}}

rem variables that go in the env section
rem set "CURL_VER=8.1.2"
rem set "CURL_URL=https://github.com/curl/curl/releases/download/curl-8_1_2/curl-8.1.2.zip"

rem 4th argument is the version of libcurl to build with in the format x.y.z
rem default to the latest version as of writing the batch file
if not "%~4"=="" (
    set "CURL_VER=%~4"
) else (
    set "CURL_VER=8.1.2"
)

set "CURL_TAG=curl-%CURL_VER:.=_%"
set "CURL_DIR=curl-%CURL_VER%"
set "CURL_ZIP=%CURL_DIR%.zip"
set "CURL_URL=https://github.com/curl/curl/releases/download/%CURL_TAG%/%CURL_ZIP%"

rem access with ex:
rem ${env:CURL_VER}
rem ${env:CURL_URL}

set "build_dir=%GITHUB_WORKSPACE%\winbuild\out\build\%preset%"
set "install_dir=%GITHUB_WORKSPACE%\winbuild\out\install\%preset%"

rem 1st argument is the build action
rem check %~1 for if curl, trurl, test, or clean were specified
if /I "%~1"=="curl" (
    call :build_curl
) else if /I "%~1"=="trurl" (
    rem check if curl prerequisite exists for trurl target
    call :check_curl
    call :verify_trurl
) else if /I "%~1"=="test" (
    call :check_curl
    rem check if trurl prerequisite exists for test target
    call :check_trurl
    rem we're ready to start testing things here
    call :test_trurl
) else if /I "%~1"=="clean" (
    rem clean just removes the out directory
    if exist "%GITHUB_WORKSPACE%\winbuild\out" (
        echo.Removing directory "winbuild\out"...
        rmdir /s /q "%GITHUB_WORKSPACE%\winbuild\out"
    ) else (
        echo.Nothing to do...
    )
    echo.
) else (
    rem default is the same as build.bat trurl
    call :check_curl
    call :verify_trurl
)

rem for %%a in (%presets%) do (
rem     echo.Building %%a...
rem     call :build_curl "%%a"
rem     echo.
rem )

rem call :build_trurl "%preset%"
rem for %%a in (%presets%) do (
rem     echo.Building %%a...
rem     call :build_project "%%a"
rem     echo.
rem )

rem for %%a in (x64-debug x64-release x86-debug x86-release) do (
rem for %%a in (%presets%) do (
rem     echo.Testing %%a...
rem     call :test_trurl "%%a"
rem     echo.
rem )

title Done
echo.Done.
if /I not "%GITHUB_ACTIONS%"=="true" (
    rem don't pause if running under CI
    pause
)
@exit

:detect_git
where git>nul 2>&1
if %errorlevel% NEQ 0 (
    echo.Please download and install Git for Windows from: https://git-scm.com/download/win
    pause
    exit /b 1
)
goto:eof

:detect_perl
where perl>nul 2>&1
if %errorlevel% NEQ 0 (
    echo.Please download and install Strawberry Perl from: https://strawberryperl.com/
    pause
    exit /b 1
)
goto:eof

:detect_python3
where python3>nul 2>&1
if %errorlevel% NEQ 0 (
    rem Python 3.10:
    rem echo.Please install Python from the Microsoft Store: https://www.microsoft.com/store/productId/9PJPW5LDXLZ5
    rem Python 3.11:
    echo.Please install Python from the Microsoft Store: https://www.microsoft.com/store/productId/9NRWMJP3717K
    pause
    exit /b 1
)
goto:eof

:get_curl
if not exist "%GITHUB_WORKSPACE%\winbuild\out" (
    mkdir "%GITHUB_WORKSPACE%\winbuild\out"
)
cd "%GITHUB_WORKSPACE%\winbuild\out"
rem clean up previous output files
rem if exist "%CURL_ZIP%" del /f /q "%CURL_ZIP%"
rem if exist "%CURL_DIR%" rmdir /s /q "%CURL_DIR%"
rem download a release version of curl
rem note: the git repo does not build release versions unless modifications are made to include/curl/curlver.h
if not exist "%CURL_ZIP%" (
    rem powershell -Command "Invoke-WebRequest '%CURL_URL%' -OutFile '%GITHUB_WORKSPACE%\winbuild\out\%CURL_ZIP%'"
    curl -LOsSf --retry 6 --retry-connrefused --max-time 999 "%CURL_URL%"
)
if not exist "%CURL_DIR%" (
    rem powershell -Command "Expand-Archive '%GITHUB_WORKSPACE%\winbuild\out\%CURL_ZIP%' -DestinationPath '%GITHUB_WORKSPACE%\winbuild\out\'"
    tar -xf %CURL_ZIP%
)
goto:eof

:build_curl
cd "%GITHUB_WORKSPACE%\winbuild"
title Build curl
echo.Building curl %CURL_VER% %preset%...
REM ~ set "preset=%~1"
REM ~ for /f "tokens=1,2 delims=-" %%a in ("%preset%") do (
    REM ~ rem set "build_arch=%%a"
    REM ~ set "Platform=%%a"
    REM ~ if "%%a"=="x86" (
        REM ~ set "build_arch=Win32"
    REM ~ ) else (
        REM ~ set "build_arch=%%a"
    REM ~ )
    REM ~ if "%%b"=="debug" (
        REM ~ set "build_type=Debug"
        REM ~ set "DEBUG=ON"
        REM ~ rem set "curl_lib=libcurl_a_debug.lib"
        REM ~ set "curl_lib=libcurl-d.lib"
    REM ~ ) else (
        REM ~ set "build_type=Release"
        REM ~ set "DEBUG=OFF"
        REM ~ rem set "curl_lib=libcurl_a.lib"
        REM ~ set "curl_lib=libcurl.lib"
    REM ~ )
REM ~ )
REM ~ if /I not "%GITHUB_ACTIONS%"=="true" (
    REM ~ rem set up build environment with the correct platform
    REM ~ call "%GITHUB_WORKSPACE%\winbuild\detect_vs.bat"
REM ~ )

call :get_curl

rem clean up previous output files
if exist "%build_dir%" rmdir /s /q "%build_dir%"
if not exist "%build_dir%" mkdir "%build_dir%"
cd "%build_dir%"

rem build curl as a static library
if not exist "%build_dir%\CMakeCache.txt" (
    rem note: these build options are roughly equivalent to the
    rem microsoft build of curl. trurl does not need the
    rem various options enabled as it is only using the parsing
    rem engine, building with the options enabled does not hurt
    rem anything, but results in a larger executable
    rem note: using static crt makes the resulting executable
    rem slightly larger, but makes it so we don't depend on
    rem vcruntime140.dll needing to be installed
    cmake -G "Visual Studio 17 2022" -A %build_arch% ^
        -DCMAKE_BINARY_DIR:PATH="%build_dir%" ^
        -DCMAKE_INSTALL_PREFIX:PATH="%install_dir%" ^
        -DBUILD_CURL_EXE=%BUILD_CURL_EXE% ^
        -DBUILD_SHARED_LIBS=OFF ^
        -DCURL_STATIC_CRT=ON ^
        -DENABLE_UNICODE=ON ^
        -DENABLE_DEBUG=%DEBUG% ^
        -DCURL_DISABLE_ALTSVC=ON ^
        -DCURL_DISABLE_GOPHER=ON ^
        -DCURL_DISABLE_LDAP=ON ^
        -DCURL_DISABLE_LDAPS=ON ^
        -DCURL_DISABLE_MQTT=ON ^
        -DCURL_DISABLE_RTSP=ON ^
        -DCURL_DISABLE_SMB=ON ^
        -DCURL_USE_SCHANNEL=ON ^
        -DUSE_WIN32_IDN=ON ^
        "%GITHUB_WORKSPACE%\winbuild\out\%CURL_DIR%"
)
cmake --build . --clean-first --config %build_type%
rem note: when visual studio is used as the generator, you need to specify build_type for the install target
cmake --build . --target install --config %build_type%
if "%build_type%"=="Debug" (
    rem if building with debug enabled copy the pdb files to the output directory
    rem curl's cmake config does not have a rule to do this automatically
    if exist "%build_dir%\lib\%build_type%\libcurl-d.pdb" (
        copy /y /b "%build_dir%\lib\%build_type%\libcurl-d.pdb" "%install_dir%\lib"
    )
    if exist "%build_dir%\src\%build_type%\curl.pdb" (
        copy /y /b "%build_dir%\src\%build_type%\curl.pdb" "%install_dir%\bin"
    )
)
if /I not "%GITHUB_ACTIONS%"=="true" (
    "%install_dir%\bin\curl.exe" --version
)
echo.
goto:eof

:check_curl
if not exist "%install_dir%\include\curl" (
    call :build_curl
)
if not exist "%install_dir%\lib\%curl_lib%" (
    call :build_curl
)
goto:eof

:build_trurl
cd "%GITHUB_WORKSPACE%\winbuild"
title Build trurl
echo.Building trurl %preset%...
REM ~ set "preset=%~1"
REM ~ for /f "tokens=1,2 delims=-" %%a in ("%preset%") do (
    REM ~ rem set "build_arch=%%a"
    REM ~ set "Platform=%%a"
    REM ~ if "%%a"=="x86" (
        REM ~ set "build_arch=Win32"
    REM ~ ) else (
        REM ~ set "build_arch=%%a"
    REM ~ )
    REM ~ if "%%b"=="debug" (
        REM ~ set "build_type=Debug"
        REM ~ set "DEBUG=ON"
        REM ~ rem set "curl_lib=libcurl_a_debug.lib"
        REM ~ set "curl_lib=libcurl-d.lib"
    REM ~ ) else (
        REM ~ set "build_type=Release"
        REM ~ set "DEBUG=OFF"
        REM ~ rem set "curl_lib=libcurl_a.lib"
        REM ~ set "curl_lib=libcurl.lib"
    REM ~ )
REM ~ )
REM ~ if /I not "%GITHUB_ACTIONS%"=="true" (
    REM ~ rem set up build environment with the correct platform
    REM ~ call "%GITHUB_WORKSPACE%\winbuild\detect_vs.bat"
REM ~ )

rem echo.build_arch=%build_arch%
rem echo.build_type=%build_type%
rem set "build_type=%build_type:~-5%"
rem echo.%build_type%
rem if "%preset:~-5%"=="debug" (
rem     set "build_type=Debug"
rem ) else (
rem     set "build_type=Release"
rem )

rem clean up previous output files
if exist "%build_dir%" rmdir /s /q "%build_dir%"
if not exist "%build_dir%" mkdir "%build_dir%"
cd "%build_dir%"

rem cmake -G "Visual Studio 17 2022" -A %build_arch% ^
rem     -DCMAKE_BINARY_DIR="%build_dir%" ^
rem     -DCMAKE_INSTALL_PREFIX="%install_dir%" ^
rem     -DCMAKE_WIN32_EXECUTABLE:BOOL=1 .\..\..\..\
rem cmake --build . --config %build_type%
if not exist "%build_dir%\CMakeCache.txt" (
    rem manually configure, generate with Ninja and compile with msvc, using vcpkg
    rem cmake -G "Ninja" ^
    rem     -DCMAKE_C_COMPILER:STRING="cl.exe" ^
    rem     -DCMAKE_CXX_COMPILER:STRING="cl.exe" ^
    rem     -DCMAKE_TOOLCHAIN_FILE:PATH="%VCPKG_ROOT%/scripts/buildsystems/vcpkg.cmake" ^
    rem     -DCMAKE_BUILD_TYPE:STRING="%build_type%" ^
    rem     -DVCPKG_TARGET_TRIPLET=%Platform%-windows-static-md ^
    rem     -DCMAKE_BINARY_DIR:PATH="%build_dir%" ^
    rem     -DCMAKE_INSTALL_PREFIX:PATH="%install_dir%" ^
    rem     "%GITHUB_WORKSPACE%\winbuild"
    
    rem configure with CMakePresets.json, generate with Ninja and compile with msvc, using vcpkg
    rem cmake --preset=%preset% "%GITHUB_WORKSPACE%\winbuild"
    
    rem manually configure, generate with Ninja and compile with msvc, specifying libcurl location
    rem cmake -G "Ninja" ^
    rem     -DCMAKE_C_COMPILER:STRING="cl.exe" ^
    rem     -DCMAKE_CXX_COMPILER:STRING="cl.exe" ^
    rem     -DCMAKE_BUILD_TYPE:STRING="%build_type%" ^
    rem     -DCMAKE_INSTALL_PREFIX:PATH="%install_dir%" ^
    rem     -DCURL_INCLUDE_DIR:PATH="%install_dir%\include" ^
    rem     -DCURL_LIBRARY:PATH="%install_dir%\lib\%curl_lib%" ^
    rem     "%GITHUB_WORKSPACE%\winbuild"
    
    rem manually configure, generate with visual studio 2022 and compile with msvc, specifying libcurl location
    cmake -G "Visual Studio 17 2022" -A %build_arch% ^
        -DCMAKE_BINARY_DIR:PATH="%build_dir%" ^
        -DCMAKE_INSTALL_PREFIX:PATH="%install_dir%\bin" ^
        -DCURL_INCLUDE_DIR:PATH="%install_dir%\include" ^
        -DCURL_LIBRARY:PATH="%install_dir%\lib\%curl_lib%" ^
        -DTRURL_STATIC_CRT=ON ^
        -DENABLE_UNICODE=ON ^
        "%GITHUB_WORKSPACE%\winbuild"
    rem note: when visual studio is used as the generator, ctest -V does not work
    rem cd to the output directory and run: python3 .\..\..\..\..\test.py to test
)
rem cmake --build "%build_dir%" --clean-first --config %build_type%
cmake --build . --clean-first --config %build_type%
rem note: when visual studio is used as the generator, you need to specify build_type for the install target
cmake --build . --target install --config %build_type%
"%install_dir%\bin\trurl.exe" --version
echo.
goto:eof

:verify_trurl
rem check for required files in the expected places
if exist "%GITHUB_WORKSPACE%\trurl.c" (
    if exist "%GITHUB_WORKSPACE%\version.h" (
        if exist "%GITHUB_WORKSPACE%\winbuild\CMakeLists.txt" (
            rem we're ready to start building things here
            call :build_trurl
        ) else (
            echo. error: Required file "winbuild\CMakeLists.txt" not found.
        )
    ) else (
        echo. error: Required file "version.h" not found.
    )
) else (
    echo. error: Required file "trurl.c" not found.
)
goto:eof

:check_trurl
if not exist "%build_dir%\trurl.exe" (
    call :verify_trurl
)
goto:eof

:test_trurl
cd "%GITHUB_WORKSPACE%\winbuild"
title Test trurl
echo.Testing trurl %preset%...
rem if exist "%install_dir%\bin" (
rem     cd "%install_dir%\bin"
if exist "%build_dir%" (
    cd "%build_dir%"
    rem create a symlink to the testfiles directory so tests work again
    if not exist "testfiles" mklink /d "testfiles" "%GITHUB_WORKSPACE%\testfiles"
    rem perl "%GITHUB_WORKSPACE%\test.pl"
    rem python3 "%GITHUB_WORKSPACE%\test.py"
    rem note: when visual studio is used as the generator, you need to specify build_type for ctest
    ctest -V -C %build_type%
) else (
    echo. note: The %preset% directory does not exist.
)
echo.
goto:eof
