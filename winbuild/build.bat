@echo off
set "basedir=%~dp0"
cd "%basedir%"
rem change underscores to spaces and set the window title
set "window_title=%~n0"
set "window_title=%window_title:_= %"
title %window_title%
call :detect_git
if %errorlevel% NEQ 0 exit /b 1
rem make sure some version of visual studio is installed
call detect_vs.bat
if %errorlevel% NEQ 0 exit /b 1
set "VCPKG_DISABLE_METRICS=1"
rem note: VCPKG_ROOT needs to be defined
if not defined VCPKG_ROOT (
    if not exist "%basedir%vcpkg" (
        git clone https://github.com/microsoft/vcpkg.git
    ) else (
        git -C vcpkg pull
    )
    set "VCPKG_ROOT=%basedir%vcpkg"
    call .\vcpkg\bootstrap-vcpkg.bat
)
set "presets=x64-debug x64-release x86-debug x86-release"
for %%a in (%presets%) do (
    call :build_project "%%a"
)
echo.Done.
pause
@exit

:detect_git
where git>nul 2>&1
if %errorlevel% NEQ 0 (
    echo.Please download and install Git for Windows from: https://git-scm.com/download/win
    pause
    exit /b 1
)
goto:eof

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
        set "build_type=Debug"
    ) else (
        set "build_type=Release"
    )
)
rem set up build environment with the correct platform for ninja
call "%basedir%detect_vs.bat"
rem echo.build_arch=%build_arch%
rem echo.build_type=%build_type%
rem set "build_type=%build_type:~-5%"
rem echo.%build_type%
rem if "%preset:~-5%"=="debug" (
rem     set "build_type=Debug"
rem ) else (
rem     set "build_type=Release"
rem )
rem if exist "%basedir%out\build\%preset%" (
rem     rmdir /s /q "%basedir%out\build\%preset%"
rem )
if not exist "%basedir%out\build\%preset%" (
    mkdir "%basedir%out\build\%preset%"
)
cd "%basedir%out\build\%preset%"
rem cmake -G "Visual Studio 17 2022" -A %build_arch% ^
rem     -DCMAKE_BINARY_DIR="%basedir%\out\build\%preset%" ^
rem     -DCMAKE_INSTALL_PREFIX="%basedir%\out\install\%preset%" ^
rem     -DCMAKE_WIN32_EXECUTABLE:BOOL=1 .\..\..\..\
rem cmake --build . --config %build_type%
if not exist "%basedir%out\build\%preset%\CMakeCache.txt" (
    cmake -G "Ninja" ^
        -DCMAKE_C_COMPILER:STRING="cl.exe" ^
        -DCMAKE_CXX_COMPILER:STRING="cl.exe" ^
        -DCMAKE_BUILD_TYPE:STRING="%build_type%" ^
        -DCMAKE_INSTALL_PREFIX:PATH="%basedir%out\install\%preset%" ^
        -DVCPKG_TARGET_TRIPLET=%Platform%-windows-static-md ^
        "%basedir%"
)
cmake --build "%basedir%out\build\%preset%" --clean-first --config %build_type%
goto:eof
