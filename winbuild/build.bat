@echo off
set "basedir=%~dp0"
cd "%basedir%"
rem change underscores to spaces and set the window title
set "window_title=%~n0"
set "window_title=%window_title:_= %"
title %window_title%
rem set build defaults based on processor architecture
if "%PROCESSOR_ARCHITECTURE%"=="ARM64" (
    set "Platform=arm64"
) else if "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
    set "Platform=x64"
) else (
    set "Platform=x86"
)
rem make sure some version of visual studio is installed
call :detect_vs
if %errorlevel% NEQ 0 exit /b 1
rem note: VCPKG_ROOT may need to be defined
set "presets=x64-debug x64-release x86-debug x86-release"
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
        set "build_type=Debug"
    ) else (
        set "build_type=Release"
    )
)
rem set up build environment with the correct platform for ninja
call :detect_vs
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
        "%basedir%"
)
cmake --build "%basedir%out\build\%preset%" --clean-first --config %build_type%
goto:eof

:detect_vs
if "%PROCESSOR_ARCHITECTURE%"=="x86" (
    set "vswhere=%ProgramFiles%\Microsoft Visual Studio\Installer\vswhere.exe"
) else (
    rem vswhere lives in ProgramFiles(x86) on both arm64 and x64
    set "vswhere=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
)
if exist "%vswhere%" (
    rem "%vswhere%" -nologo -latest -products * -requires Microsoft.VisualStudio.Product.BuildTools -property installationPath
    rem "%vswhere%" -nologo -latest -products * -requires Microsoft.VisualStudio.VC.vcvars -property installationPath
    rem "%vswhere%" -nologo -latest -products * -requires Microsoft.VisualStudio.VC.vcvars -find VC\Auxiliary\Build\vcvars*.bat
    for /f "tokens=*" %%a in ('"%vswhere%" -nologo -latest -products * -requires Microsoft.VisualStudio.VC.vcvars -property installationPath') do (
        set "vspath=%%a"
    )
)
if "%PROCESSOR_ARCHITECTURE%"=="ARM64" (
    rem arm64 host to build arm64:  vcvarsarm64.bat
    set "vcvars=%vspath%\VC\Auxiliary\Build\vcvarsarm64.bat"
    if "%Platform%"=="x86" (
        rem arm64 host to build x86:    vcvarsarm64_x86.bat
        set "vcvars=%vspath%\VC\Auxiliary\Build\vcvarsarm64_x86.bat"
    ) else if "%Platform%"=="x64" (
        rem arm64 host to build x64:    vcvarsarm64_amd64.bat
        set "vcvars=%vspath%\VC\Auxiliary\Build\vcvarsarm64_amd64.bat"
    )
) else if "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
    rem x64 host to build x64:      vcvars64.bat
    rem set "vcvars=%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvars64.bat"
    set "vcvars=%vspath%\VC\Auxiliary\Build\vcvars64.bat"
    if "%Platform%"=="x86" (
        rem x64 host to build x86:      vcvarsamd64_x86.bat
        set "vcvars=%vspath%\VC\Auxiliary\Build\vcvarsamd64_x86.bat"
    ) else if "%Platform%"=="arm64" (
        rem x64 host to build arm64:    vcvarsamd64_arm64.bat
        set "vcvars=%vspath%\VC\Auxiliary\Build\vcvarsamd64_arm64.bat"
    )
) else (
    rem x86 host to build x86:      vcvars32.bat
    rem set "vcvars=%ProgramFiles%\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvars32.bat"
    set "vcvars=%vspath%\VC\Auxiliary\Build\vcvars32.bat"
    if "%Platform%"=="x64" (
        rem x86 host to build x64:      vcvarsx86_amd64.bat
        set "vcvars=%vspath%\VC\Auxiliary\Build\vcvarsx86_amd64.bat"
    ) else if "%Platform%"=="arm64" (
        rem x86 host to build arm64:    vcvarsx86_arm64.bat
        set "vcvars=%vspath%\VC\Auxiliary\Build\vcvarsx86_arm64.bat"
    )
)
rem echo.vcvars=%vcvars%
if not exist "%vcvars%" (
    echo.Please download and install Microsoft C++ Build Tools from: https://visualstudio.microsoft.com/visual-cpp-build-tools/
    pause
    exit /b 1
)
call "%vcvars%">nul 2>&1
goto:eof
