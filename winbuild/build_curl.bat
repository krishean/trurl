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

rem GITHUB_ACTIONS - Always set to true when GitHub Actions is running the
rem workflow. You can use this variable to differentiate when
rem tests are being run locally or by GitHub Actions.
if not "%GITHUB_ACTIONS%"=="true" (
    rem make sure some version of visual studio is installed
    rem this should be handled by "ilammy/msvc-dev-cmd@v1" in github actions
    call "%GITHUB_WORKSPACE%\winbuild\detect_vs.bat"
    if %errorlevel% NEQ 0 exit /b 1
)

rem variables that go in the matrix section
rem set "presets=x64-debug x64-release x86-debug x86-release"
rem set "presets=x64-release"

if not "%~1"=="" (
    set "preset=%~1"
) else (
    set "preset=%Platform%-release"
)

rem access with ex:
rem ${{matrix.PRESET}}

rem variables that go in the env section
set "CURL_VER=8.0.1"
set "CURL_URL=https://github.com/curl/curl/releases/download/curl-8_0_1/curl-8.0.1.zip"

rem access with ex:
rem ${env:CURL_VER}
rem ${env:CURL_URL}

rem we're ready to start building things here
cd winbuild

echo.Building %preset%...
call :build_project "%preset%"
echo.

rem for %%a in (%presets%) do (
rem     echo.Building %%a...
rem     call :build_project "%%a"
rem     echo.
rem )

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
if not "%GITHUB_ACTIONS%"=="true" (
    rem set up build environment with the correct platform
    call "%GITHUB_WORKSPACE%\winbuild\detect_vs.bat"
)

if not exist "%GITHUB_WORKSPACE%\winbuild\out" mkdir "%GITHUB_WORKSPACE%\winbuild\out"
cd "%GITHUB_WORKSPACE%\winbuild\out"

rem clean up previous output files
rem if exist "curl-%CURL_VER%" rmdir /s /q "curl-%CURL_VER%"
rem if exist "curl-%CURL_VER%.zip" del /f /q "curl-%CURL_VER%.zip"
rem if exist "curl\%preset%" rmdir /s /q "curl\%preset%"

rem download a release version of curl
rem note: the git repo does not build release versions unless modifications are made to include/curl/curlver.h
if not exist "curl-%CURL_VER%.zip" (
    rem powershell -Command "Invoke-WebRequest '%CURL_URL%' -OutFile '%GITHUB_WORKSPACE%\winbuild\out\curl-%CURL_VER%.zip'"
    curl -LOsSf --retry 6 --retry-connrefused --max-time 999 "%CURL_URL%"
)
if not exist "curl-%CURL_VER%" (
    rem powershell -Command "Expand-Archive '%GITHUB_WORKSPACE%\winbuild\out\curl-%CURL_VER%.zip' -DestinationPath '%GITHUB_WORKSPACE%\winbuild\out\'"
    tar -xf curl-%CURL_VER%.zip
)

if exist "%GITHUB_WORKSPACE%\winbuild\out\build\%preset%" (
    rmdir /s /q "%GITHUB_WORKSPACE%\winbuild\out\build\%preset%"
)
if not exist "%GITHUB_WORKSPACE%\winbuild\out\build\%preset%" (
    mkdir "%GITHUB_WORKSPACE%\winbuild\out\build\%preset%"
)
cd "%GITHUB_WORKSPACE%\winbuild\out\build\%preset%"

rem build curl as a static library
if not exist "%GITHUB_WORKSPACE%\winbuild\out\build\%preset%\CMakeCache.txt" (
    rem -DCURL_STATIC_CRT=ON
    rem note: these build options are roughly equivalent to the microsoft build of curl
    rem trurl does not need the various options enabled as it is only using the parsing engine
    rem building with the options enabled does not hurt anything, but results in a larger executable
    cmake -G "Visual Studio 17 2022" -A %build_arch% ^
        -DCMAKE_BINARY_DIR:PATH="%GITHUB_WORKSPACE%\winbuild\out\build\%preset%" ^
        -DCMAKE_INSTALL_PREFIX:PATH="%GITHUB_WORKSPACE%\winbuild\out\install\%preset%" ^
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
        "%GITHUB_WORKSPACE%\winbuild\out\curl-8.0.1"
)
cmake --build . --clean-first --config %build_type%
rem note: when visual studio is used as the generator, you need to specify build_type for the install target
cmake --build . --target install --config %build_type%
if "%build_type%"=="Debug" (
    rem if building with debug enabled copy the pdb files to the output directory
    rem curl's cmake config does not have a rule to do this automatically
    if exist "%GITHUB_WORKSPACE%\winbuild\out\build\%preset%\lib\%build_type%\libcurl-d.pdb" (
        copy /y /b "%GITHUB_WORKSPACE%\winbuild\out\build\%preset%\lib\%build_type%\libcurl-d.pdb" "%GITHUB_WORKSPACE%\winbuild\out\install\%preset%\lib"
    )
    if exist "%GITHUB_WORKSPACE%\winbuild\out\build\%preset%\src\%build_type%\curl.pdb" (
        copy /y /b "%GITHUB_WORKSPACE%\winbuild\out\build\%preset%\src\%build_type%\curl.pdb" "%GITHUB_WORKSPACE%\winbuild\out\install\%preset%\bin"
    )
)
"%GITHUB_WORKSPACE%\winbuild\out\install\%preset%\bin\curl.exe" --version
goto:eof
