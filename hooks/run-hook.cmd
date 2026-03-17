@echo off
setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
set "PLUGIN_ROOT=%SCRIPT_DIR%.."

powershell -NoProfile -Command "& '%PLUGIN_ROOT%\hooks\%~1'"

endlocal
