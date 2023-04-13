@echo off
set "basedir=%~dp0"
cd "%basedir%"
rem change underscores to spaces and set the window title
set "window_title=%~n0"
set "window_title=%window_title:_= %"
title %window_title%
call :detect_perl
if %errorlevel% NEQ 0 exit /b 1
for %%a in (x64-debug x64-release x86-debug x86-release) do (
    if exist "%basedir%out\build\%%a" (
        cd "%basedir%out\build\%%a"
        echo.Testing %%a...
        perl "%basedir%..\test.pl"
    ) else (
        echo.Notice: The %%a directory does not exist.
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
