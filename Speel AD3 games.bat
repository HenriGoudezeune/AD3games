@echo off
rem Eerst de Godot-cache (.godot/, niet in git) bijwerken: nieuwe scripts uit een
rem andere sessie (class_name) zijn anders onbekend en de hub blijft grijs.
"C:\Users\henri\tools\godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path "%~dp0." --import >nul 2>&1
start "" "C:\Users\henri\tools\godot\Godot_v4.7.2-stable_win64.exe" --path "%~dp0."
