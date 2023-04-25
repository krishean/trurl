@echo off
set "GITHUB_WORKSPACE=%~dp0"
cd "%GITHUB_WORKSPACE%"
rem change underscores to spaces and set the window title
set "window_title=%~n0"
set "window_title=%window_title:_= %"
title %window_title%

rem variables that go in the matrix section
set "presets=x64-debug x64-release x86-debug x86-release"

rem access with ex:
rem ${{matrix.PRESET}}

rem variables that go in the env section
set "CURL_VER=8.0.1"
set "CURL_URL=https://github.com/curl/curl/releases/download/curl-8_0_1/curl-8.0.1.zip"

rem access with ex:
rem ${env:CURL_VER}
rem ${env:CURL_URL}

rem set up the visual studio build environment
rem this should be handled by "ilammy/msvc-dev-cmd@v1" in github actions
call "%GITHUB_WORKSPACE%detect_vs.bat"
if %errorlevel% NEQ 0 exit /b 1

rem set "presets=x64-release"
for %%a in (%presets%) do (
    call :build_project "%%a"
)

echo.Done.
pause
@exit

:build_project
set "preset=%~1"
for /f "tokens=1,2 delims=-" %%a in ("%preset%") do (
    rem set "build_arch=%%a"
    set "Platform=%%a"
    if "%%a"=="x86" (
        set "build_arch=Win32"
    ) else (
        set "build_arch=%%a"
    )
    if "%%b"=="debug" (
        set "build_type=Debug"
        set "DEBUG=ON"
        rem set "curl_lib=libcurl_a_debug.lib"
        set "curl_lib=libcurl-d.lib"
    ) else (
        set "build_type=Release"
        set "DEBUG=OFF"
        rem set "curl_lib=libcurl_a.lib"
        set "curl_lib=libcurl.lib"
    )
)
rem set up build environment with the correct platform
call "%GITHUB_WORKSPACE%detect_vs.bat"

if not exist "%GITHUB_WORKSPACE%out" mkdir "%GITHUB_WORKSPACE%out"
cd "%GITHUB_WORKSPACE%out"

rem clean up previous output files
rem if exist "curl-%CURL_VER%" rmdir /s /q "curl-%CURL_VER%"
rem if exist "curl-%CURL_VER%.zip" del /f /q "curl-%CURL_VER%.zip"
rem if exist "curl\%preset%" rmdir /s /q "curl\%preset%"

rem download a release version of curl
rem note: the git repo does not build release versions unless modifications are made to include/curl/curlver.h
if not exist "curl-%CURL_VER%.zip" (
    rem powershell -Command "Invoke-WebRequest '%CURL_URL%' -OutFile '%GITHUB_WORKSPACE%curl-%CURL_VER%.zip'"
    curl -LOsSf --retry 6 --retry-connrefused --max-time 999 "%CURL_URL%"
)
if not exist "curl-%CURL_VER%" (
    rem powershell -Command "Expand-Archive '%GITHUB_WORKSPACE%curl-%CURL_VER%.zip' -DestinationPath '%GITHUB_WORKSPACE%'"
    tar -xf curl-%CURL_VER%.zip
)

if exist "%GITHUB_WORKSPACE%out\build\%preset%" (
    rmdir /s /q "%GITHUB_WORKSPACE%out\build\%preset%"
)
if not exist "%GITHUB_WORKSPACE%out\build\%preset%" (
    mkdir "%GITHUB_WORKSPACE%out\build\%preset%"
)
cd "%GITHUB_WORKSPACE%out\build\%preset%"

rem build curl as a static library
if not exist "%GITHUB_WORKSPACE%out\build\%preset%\CMakeCache.txt" (
    rem -DCURL_STATIC_CRT=ON
    rem note: these build options are roughly equivalent to the microsoft build of curl
    rem trurl does not need the various options enabled as it is only using the parsing engine
    rem building with the options enabled does not hurt anything, but results in a larger executable
    cmake -G "Visual Studio 17 2022" -A %build_arch% ^
        -DCMAKE_BINARY_DIR:PATH="%GITHUB_WORKSPACE%out\build\%preset%" ^
        -DCMAKE_INSTALL_PREFIX:PATH="%GITHUB_WORKSPACE%out\install\%preset%" ^
        -DBUILD_SHARED_LIBS=OFF ^
        -DENABLE_DEBUG=%DEBUG% ^
        -DCURL_USE_SCHANNEL=ON ^
        -DUSE_WIN32_IDN=ON ^
        -DENABLE_UNICODE=ON ^
        -DCURL_DISABLE_ALTSVC=ON ^
        -DCURL_DISABLE_GOPHER=ON ^
        -DCURL_DISABLE_LDAP=ON ^
        -DCURL_DISABLE_LDAPS=ON ^
        -DCURL_DISABLE_MQTT=ON ^
        -DCURL_DISABLE_RTSP=ON ^
        -DCURL_DISABLE_SMB=ON ^
        "%GITHUB_WORKSPACE%out\curl-8.0.1"
)
cmake --build . --clean-first --config %build_type%
rem note: when visual studio is used as the generator, you need to specify build_type for the install target
cmake --build . --target install --config %build_type%
if "%build_type%"=="Debug" (
    rem if building with debug enabled copy the pdb files to the output directory
    rem curl's cmake config does not have a rule to do this automatically
    if exist "%GITHUB_WORKSPACE%out\build\%preset%\lib\%build_type%\libcurl-d.pdb" (
        copy /y /b "%GITHUB_WORKSPACE%out\build\%preset%\lib\%build_type%\libcurl-d.pdb" "%GITHUB_WORKSPACE%out\install\%preset%\lib"
    )
    if exist "%GITHUB_WORKSPACE%out\build\%preset%\src\%build_type%\curl.pdb" (
        copy /y /b "%GITHUB_WORKSPACE%out\build\%preset%\src\%build_type%\curl.pdb" "%GITHUB_WORKSPACE%out\install\%preset%\bin"
    )
)
"%GITHUB_WORKSPACE%out\install\%preset%\bin\curl.exe" --version
echo.
goto:eof
