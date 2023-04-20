@echo off
set "GITHUB_WORKSPACE=%~dp0"
cd "%GITHUB_WORKSPACE%"
rem change underscores to spaces and set the window title
set "window_title=%~n0"
set "window_title=%window_title:_= %"
title %window_title%

rem variables that go in the matrix section
set "DEBUG=no"
set "ENABLE_UNICODE=yes"

rem access with ex:
rem ${{matrix.DEBUG}}
rem ${{matrix.ENABLE_UNICODE}}

rem variables that go in the env section
set "CURL_VER=8.0.1"
set "CURL_URL=https://github.com/curl/curl/releases/download/curl-8_0_1/curl-8.0.1.zip"

rem access with ex:
rem ${env:CURL_VER}
rem ${env:CURL_URL}

rem set up visual studio build environment
rem this should be handled by "ilammy/msvc-dev-cmd@v1" in github actions
call detect_vs.bat
if %errorlevel% NEQ 0 exit /b 1

rem clean up previous build files
if exist "curl-%CURL_VER%" rmdir /s /q "curl-%CURL_VER%"
rem if exist "curl-%CURL_VER%.zip" del /f /q "curl-%CURL_VER%.zip"
if exist "curl" rmdir /s /q "curl"

rem note: the git repo does not build release versions unless modifications are made to include/curl/curlver.h
if not exist "curl-%CURL_VER%.zip" (
    rem powershell -Command "Invoke-WebRequest '%CURL_URL%' -OutFile '%GITHUB_WORKSPACE%curl-%CURL_VER%.zip'"
    curl -LOsSf --retry 6 --retry-connrefused --max-time 999 "%CURL_URL%"
)
rem powershell -Command "Expand-Archive '%GITHUB_WORKSPACE%curl-%CURL_VER%.zip' -DestinationPath '%GITHUB_WORKSPACE%'"
tar -xf curl-%CURL_VER%.zip
cd curl-%CURL_VER%

rem build curl as a static library
cd winbuild && ^
nmake /f Makefile.vc MODE=static^
    WITH_PREFIX=%GITHUB_WORKSPACE%curl^
    ENABLE_SCHANNEL=yes^
    MACHINE=%Platform%^
    DEBUG=%DEBUG%^
    GEN_PDB=%DEBUG%^
    ENABLE_UNICODE=%ENABLE_UNICODE% && ^
"%GITHUB_WORKSPACE%curl\bin\curl.exe" -V

echo.Done.
pause
@exit
