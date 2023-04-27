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

call "%GITHUB_WORKSPACE%\winbuild\build.bat" clean

@exit
