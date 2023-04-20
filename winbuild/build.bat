@echo off
set "GITHUB_WORKSPACE=%~dp0"
cd "%GITHUB_WORKSPACE%"
rem change underscores to spaces and set the window title
set "window_title=%~n0"
set "window_title=%window_title:_= %"
title %window_title%
rem call :detect_git
rem if %errorlevel% NEQ 0 exit /b 1
rem make sure some version of visual studio is installed
rem this should be handled by "ilammy/msvc-dev-cmd@v1" in github actions
call detect_vs.bat
if %errorlevel% NEQ 0 exit /b 1
rem set "VCPKG_DISABLE_METRICS=1"
rem note: VCPKG_ROOT needs to be defined
rem if not defined VCPKG_ROOT (
rem     if not exist "%GITHUB_WORKSPACE%vcpkg" (
rem         git clone https://github.com/microsoft/vcpkg.git
rem     ) else (
rem         git -C vcpkg pull
rem     )
rem     set "VCPKG_ROOT=%GITHUB_WORKSPACE%vcpkg"
rem     call .\vcpkg\bootstrap-vcpkg.bat
    rem .\vcpkg\vcpkg x-update-baseline
rem )
rem set "presets=x64-debug x64-release x86-debug x86-release"
set "presets=x64-release"
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
call "%GITHUB_WORKSPACE%detect_vs.bat"
rem echo.build_arch=%build_arch%
rem echo.build_type=%build_type%
rem set "build_type=%build_type:~-5%"
rem echo.%build_type%
rem if "%preset:~-5%"=="debug" (
rem     set "build_type=Debug"
rem ) else (
rem     set "build_type=Release"
rem )
rem if exist "%GITHUB_WORKSPACE%out\build\%preset%" (
rem     rmdir /s /q "%GITHUB_WORKSPACE%out\build\%preset%"
rem )
if not exist "%GITHUB_WORKSPACE%out\build\%preset%" (
    mkdir "%GITHUB_WORKSPACE%out\build\%preset%"
)
cd "%GITHUB_WORKSPACE%out\build\%preset%"
rem cmake -G "Visual Studio 17 2022" -A %build_arch% ^
rem     -DCMAKE_BINARY_DIR="%GITHUB_WORKSPACE%\out\build\%preset%" ^
rem     -DCMAKE_INSTALL_PREFIX="%GITHUB_WORKSPACE%\out\install\%preset%" ^
rem     -DCMAKE_WIN32_EXECUTABLE:BOOL=1 .\..\..\..\
rem cmake --build . --config %build_type%
if not exist "%GITHUB_WORKSPACE%out\build\%preset%\CMakeCache.txt" (
    
    rem manually configure, generate with Ninja and compile with msvc, using vcpkg
    rem cmake -G "Ninja" ^
    rem     -DCMAKE_C_COMPILER:STRING="cl.exe" ^
    rem     -DCMAKE_CXX_COMPILER:STRING="cl.exe" ^
    rem     -DCMAKE_TOOLCHAIN_FILE:PATH="%VCPKG_ROOT%/scripts/buildsystems/vcpkg.cmake" ^
    rem     -DCMAKE_BUILD_TYPE:STRING="%build_type%" ^
    rem     -DVCPKG_TARGET_TRIPLET=%Platform%-windows-static-md ^
    rem     -DCMAKE_BINARY_DIR:PATH="%GITHUB_WORKSPACE%\out\build\%preset%" ^
    rem     -DCMAKE_INSTALL_PREFIX:PATH="%GITHUB_WORKSPACE%out\install\%preset%" ^
    rem     "%GITHUB_WORKSPACE%"
    
    rem configure with CMakePresets.json, generate with Ninja and compile with msvc, using vcpkg
    rem cmake --preset=%preset% "%GITHUB_WORKSPACE%"
    
    rem manually configure, generate with Ninja and compile with msvc, specifying libcurl location
    cmake -G "Ninja" ^
        -DCMAKE_C_COMPILER:STRING="cl.exe" ^
        -DCMAKE_CXX_COMPILER:STRING="cl.exe" ^
        -DCMAKE_BUILD_TYPE:STRING="%build_type%" ^
        -DCMAKE_INSTALL_PREFIX:PATH="%GITHUB_WORKSPACE%out\install\%preset%" ^
        -DCURL_INCLUDE_DIR:PATH="%GITHUB_WORKSPACE%curl\include" ^
        -DCURL_LIBRARY:PATH="%GITHUB_WORKSPACE%curl\lib\libcurl_a.lib" ^
        "%GITHUB_WORKSPACE%"
    
    rem manually configure, generate with visual studio 2022 and compile with msvc, specifying libcurl location
    rem cmake -G "Visual Studio 17 2022" -A %Platform% ^
    rem     -DCMAKE_BINARY_DIR:PATH="%GITHUB_WORKSPACE%\out\build\%preset%" ^
    rem     -DCMAKE_INSTALL_PREFIX:PATH="%GITHUB_WORKSPACE%out\install\%preset%" ^
    rem     -DCURL_INCLUDE_DIR:PATH="%GITHUB_WORKSPACE%curl\include" ^
    rem     -DCURL_LIBRARY:PATH="%GITHUB_WORKSPACE%curl\lib\libcurl_a.lib" ^
    rem     "%GITHUB_WORKSPACE%"
    rem note: when visual studio is used as the generator, ctest -V does not work
    rem cd to the output directory and run: python3 .\..\..\..\..\test.py to test
)
rem cmake --build "%GITHUB_WORKSPACE%out\build\%preset%" --clean-first --config %build_type%
cmake --build . --clean-first --config %build_type%
rem cmake --build . --target install
goto:eof
