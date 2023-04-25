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
    rem call :detect_git
    rem if %errorlevel% NEQ 0 exit /b 1
    rem make sure some version of visual studio is installed
    rem this should be handled by "ilammy/msvc-dev-cmd@v1" in github actions
    call "%GITHUB_WORKSPACE%\winbuild\detect_vs.bat"
    if %errorlevel% NEQ 0 exit /b 1
)
rem set "VCPKG_DISABLE_METRICS=1"
rem note: VCPKG_ROOT needs to be defined
rem if not defined VCPKG_ROOT (
rem     if not exist "%GITHUB_WORKSPACE%\winbuild\vcpkg" (
rem         git clone https://github.com/microsoft/vcpkg.git
rem     ) else (
rem         git -C vcpkg pull
rem     )
rem     set "VCPKG_ROOT=%GITHUB_WORKSPACE%\winbuild\vcpkg"
rem     call .\vcpkg\bootstrap-vcpkg.bat
    rem .\vcpkg\vcpkg x-update-baseline
rem )
rem set "presets=x64-debug x64-release x86-debug x86-release"
rem set "presets=x64-release"

if not "%~1"=="" (
    set "preset=%~1"
) else (
    set "preset=%Platform%-release"
)

rem check for required files in the expected places
if exist "trurl.c" (
    if exist "version.h" (
        if exist "winbuild\CMakeLists.txt" (
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
        ) else (
            echo. error: Required file "winbuild\CMakeLists.txt" not found.
        )
    ) else (
        echo. error: Required file "version.h" not found.
    )
) else (
    echo. error: Required file "trurl.c" not found.
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
rem echo.build_arch=%build_arch%
rem echo.build_type=%build_type%
rem set "build_type=%build_type:~-5%"
rem echo.%build_type%
rem if "%preset:~-5%"=="debug" (
rem     set "build_type=Debug"
rem ) else (
rem     set "build_type=Release"
rem )
if exist "%GITHUB_WORKSPACE%\winbuild\out\build\%preset%" (
    rmdir /s /q "%GITHUB_WORKSPACE%\winbuild\out\build\%preset%"
)
if not exist "%GITHUB_WORKSPACE%\winbuild\out\build\%preset%" (
    mkdir "%GITHUB_WORKSPACE%\winbuild\out\build\%preset%"
)
cd "%GITHUB_WORKSPACE%\winbuild\out\build\%preset%"
rem cmake -G "Visual Studio 17 2022" -A %build_arch% ^
rem     -DCMAKE_BINARY_DIR="%GITHUB_WORKSPACE%\winbuild\out\build\%preset%" ^
rem     -DCMAKE_INSTALL_PREFIX="%GITHUB_WORKSPACE%\winbuild\out\install\%preset%" ^
rem     -DCMAKE_WIN32_EXECUTABLE:BOOL=1 .\..\..\..\
rem cmake --build . --config %build_type%
if not exist "%GITHUB_WORKSPACE%\winbuild\out\build\%preset%\CMakeCache.txt" (
    
    rem manually configure, generate with Ninja and compile with msvc, using vcpkg
    rem cmake -G "Ninja" ^
    rem     -DCMAKE_C_COMPILER:STRING="cl.exe" ^
    rem     -DCMAKE_CXX_COMPILER:STRING="cl.exe" ^
    rem     -DCMAKE_TOOLCHAIN_FILE:PATH="%VCPKG_ROOT%/scripts/buildsystems/vcpkg.cmake" ^
    rem     -DCMAKE_BUILD_TYPE:STRING="%build_type%" ^
    rem     -DVCPKG_TARGET_TRIPLET=%Platform%-windows-static-md ^
    rem     -DCMAKE_BINARY_DIR:PATH="%GITHUB_WORKSPACE%\winbuild\out\build\%preset%" ^
    rem     -DCMAKE_INSTALL_PREFIX:PATH="%GITHUB_WORKSPACE%\winbuild\out\install\%preset%" ^
    rem     "%GITHUB_WORKSPACE%\winbuild"
    
    rem configure with CMakePresets.json, generate with Ninja and compile with msvc, using vcpkg
    rem cmake --preset=%preset% "%GITHUB_WORKSPACE%\winbuild"
    
    rem manually configure, generate with Ninja and compile with msvc, specifying libcurl location
    rem cmake -G "Ninja" ^
    rem     -DCMAKE_C_COMPILER:STRING="cl.exe" ^
    rem     -DCMAKE_CXX_COMPILER:STRING="cl.exe" ^
    rem     -DCMAKE_BUILD_TYPE:STRING="%build_type%" ^
    rem     -DCMAKE_INSTALL_PREFIX:PATH="%GITHUB_WORKSPACE%\winbuild\out\install\%preset%" ^
    rem     -DCURL_INCLUDE_DIR:PATH="%GITHUB_WORKSPACE%\winbuild\out\curl\%preset%\include" ^
    rem     -DCURL_LIBRARY:PATH="%GITHUB_WORKSPACE%\winbuild\out\curl\%preset%\lib\%curl_lib%" ^
    rem     "%GITHUB_WORKSPACE%\winbuild"
    
    rem manually configure, generate with visual studio 2022 and compile with msvc, specifying libcurl location
    cmake -G "Visual Studio 17 2022" -A %build_arch% ^
        -DCMAKE_BINARY_DIR:PATH="%GITHUB_WORKSPACE%\winbuild\out\build\%preset%" ^
        -DCMAKE_INSTALL_PREFIX:PATH="%GITHUB_WORKSPACE%\winbuild\out\install\%preset%\bin" ^
        -DCURL_INCLUDE_DIR:PATH="%GITHUB_WORKSPACE%\winbuild\out\install\%preset%\include" ^
        -DCURL_LIBRARY:PATH="%GITHUB_WORKSPACE%\winbuild\out\install\%preset%\lib\%curl_lib%" ^
        "%GITHUB_WORKSPACE%\winbuild"
    rem note: when visual studio is used as the generator, ctest -V does not work
    rem cd to the output directory and run: python3 .\..\..\..\..\test.py to test
)
rem cmake --build "%GITHUB_WORKSPACE%\winbuild\out\build\%preset%" --clean-first --config %build_type%
cmake --build . --clean-first --config %build_type%
rem note: when visual studio is used as the generator, you need to specify build_type for the install target
cmake --build . --target install --config %build_type%
"%GITHUB_WORKSPACE%\winbuild\out\install\%preset%\bin\trurl.exe" --version
goto:eof
