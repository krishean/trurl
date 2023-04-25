@echo off
set "basedir=%~dp0"
cd "%basedir%"
rem change underscores to spaces and set the window title
set "window_title=%~n0"
set "window_title=%window_title:_= %"
title %window_title%
rem call :detect_perl
call :detect_python3
if %errorlevel% NEQ 0 exit /b 1
rem make sure some version of visual studio is installed
call detect_vs.bat
if %errorlevel% NEQ 0 exit /b 1
for %%a in (x64-debug x64-release x86-debug x86-release) do (
    if exist "%basedir%out\install\%%a\bin" (
        cd "%basedir%out\install\%%a\bin"
        echo.Testing %%a...
        rem perl "%basedir%..\test.pl"
        python3 "%basedir%..\test.py"
        rem ctest -V
    ) else (
        echo. note: The %%a directory does not exist.
    )
)
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
