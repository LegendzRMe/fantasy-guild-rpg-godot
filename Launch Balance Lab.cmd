@echo off
setlocal
set "ROOT=%~dp0"
set "ROOT=%ROOT:~0,-1%"
set "GODOT="

for /f "delims=" %%G in ('where godot4.exe 2^>nul') do if not defined GODOT set "GODOT=%%G"
for /f "delims=" %%G in ('where godot.exe 2^>nul') do if not defined GODOT set "GODOT=%%G"
if not defined GODOT (
    for /d %%D in ("%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_*") do (
        for %%G in ("%%~fD\Godot_v*-stable_win64.exe") do if not defined GODOT if exist "%%~fG" set "GODOT=%%~fG"
    )
)

if not defined GODOT (
    echo Godot could not be found.
    echo Open Godot once, or reinstall it through WinGet, then try again.
    pause
    exit /b 1
)

start "Fantasy Guild Balance Lab" "%GODOT%" --path "%ROOT%" res://balance_lab.tscn
endlocal
