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
    rem call :detect_perl
    call :detect_python3
    if %errorlevel% NEQ 0 exit /b 1
    rem make sure some version of visual studio is installed
    rem this should be handled by "ilammy/msvc-dev-cmd@v1" in github actions
    call "%GITHUB_WORKSPACE%\winbuild\detect_vs.bat"
    if %errorlevel% NEQ 0 exit /b 1
)

rem set "presets=x64-debug x64-release x86-debug x86-release"
rem set "presets=x64-release"

if not "%~1"=="" (
    set "preset=%~1"
) else (
    set "preset=%Platform%-release"
)

rem we're ready to start testing things here
cd winbuild

echo.Testing %preset%...
call :test_project "%preset%"
echo.

rem for %%a in (x64-debug x64-release x86-debug x86-release) do (
rem for %%a in (%presets%) do (
rem     echo.Testing %%a...
rem     call :test_project "%%a"
rem     echo.
rem )
echo.Done.
pause
@exit

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

:test_project
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

rem if exist "%GITHUB_WORKSPACE%\winbuild\out\install\%preset%\bin" (
rem     cd "%GITHUB_WORKSPACE%\winbuild\out\install\%preset%\bin"
if exist "%GITHUB_WORKSPACE%\winbuild\out\build\%preset%" (
    cd "%GITHUB_WORKSPACE%\winbuild\out\build\%preset%"
    
    rem if not "%GITHUB_ACTIONS%"=="true" (
    rem     rem set up build environment with the correct platform
    rem     call "%GITHUB_WORKSPACE%\winbuild\detect_vs.bat"
    rem )
    
    rem perl "%GITHUB_WORKSPACE%\test.pl"
    rem python3 "%GITHUB_WORKSPACE%\test.py"
    ctest -V -C %build_type%
) else (
    echo. note: The %%a directory does not exist.
)

goto:eof
