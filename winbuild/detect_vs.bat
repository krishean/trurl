
rem detect_vs.bat - detect visual studio and set up the build environment
rem the target build platform can be set using the Platform variable
rem if the Platform variable is not set it will default to the native processor architecture
rem if visual studio is not detected it will print a message and exit with a status code of 1

if not defined Platform (
    rem set build defaults based on processor architecture
    if "%PROCESSOR_ARCHITECTURE%"=="ARM64" (
        set "Platform=arm64"
    ) else if "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
        set "Platform=x64"
    ) else (
        set "Platform=x86"
    )
)
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
