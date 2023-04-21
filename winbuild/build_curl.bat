@echo off
set "GITHUB_WORKSPACE=%~dp0"
cd "%GITHUB_WORKSPACE%"
rem change underscores to spaces and set the window title
set "window_title=%~n0"
set "window_title=%window_title:_= %"
title %window_title%

rem variables that go in the matrix section
rem set "DEBUG=no"
set "ENABLE_UNICODE=yes"
set "presets=x64-debug x64-release x86-debug x86-release"

rem access with ex:
rem ${{matrix.DEBUG}}
rem ${{matrix.ENABLE_UNICODE}}

rem variables that go in the env section
set "CURL_VER=8.0.1"
set "CURL_URL=https://github.com/curl/curl/releases/download/curl-8_0_1/curl-8.0.1.zip"

rem access with ex:
rem ${env:CURL_VER}
rem ${env:CURL_URL}

rem set up the visual studio build environment
rem this should be handled by "ilammy/msvc-dev-cmd@v1" in github actions
call detect_vs.bat
if %errorlevel% NEQ 0 exit /b 1

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
    rem if "%%a"=="x86" (
    rem     set "build_arch=Win32"
    rem ) else (
    rem     set "build_arch=%%a"
    rem )
    if "%%b"=="debug" (
        set "DEBUG=yes"
    ) else (
        set "DEBUG=no"
    )
)

cd "%GITHUB_WORKSPACE%"

rem set up build environment with the correct platform for ninja
call detect_vs.bat

if not exist "%GITHUB_WORKSPACE%out" mkdir out
cd out

rem clean up previous output files
if exist "curl-%CURL_VER%" rmdir /s /q "curl-%CURL_VER%"
rem if exist "curl-%CURL_VER%.zip" del /f /q "curl-%CURL_VER%.zip"
if exist "curl\%preset%" rmdir /s /q "curl\%preset%"

rem download a release version of curl
rem note: the git repo does not build release versions unless modifications are made to include/curl/curlver.h
if not exist "curl-%CURL_VER%.zip" (
    rem powershell -Command "Invoke-WebRequest '%CURL_URL%' -OutFile '%GITHUB_WORKSPACE%curl-%CURL_VER%.zip'"
    curl -LOsSf --retry 6 --retry-connrefused --max-time 999 "%CURL_URL%"
)
rem powershell -Command "Expand-Archive '%GITHUB_WORKSPACE%curl-%CURL_VER%.zip' -DestinationPath '%GITHUB_WORKSPACE%'"
tar -xf curl-%CURL_VER%.zip
cd curl-%CURL_VER%

rem build curl as a static library
rem note: Platform is set by detect_vs.bat and is usually the native system architecture
cd winbuild && ^
nmake /f Makefile.vc MODE=static^
    WITH_PREFIX="%GITHUB_WORKSPACE%out\curl\%preset%"^
    ENABLE_SCHANNEL=yes^
    MACHINE=%Platform%^
    DEBUG=%DEBUG%^
    GEN_PDB=%DEBUG%^
    ENABLE_UNICODE=%ENABLE_UNICODE% && ^
"%GITHUB_WORKSPACE%out\curl\%preset%\bin\curl.exe" -V

echo.

goto:eof
