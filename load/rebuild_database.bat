@echo off
REM Rebuilds db\ghg_capstone_project.db from scratch:
REM drops and recreates every raw table, then loads every CSV in data\.
REM Close any program that has the database open first (it locks the file). Then double-click this file.

REM Change this to where sqlite3.exe is on your computer:
set SQLITE="C:\path\to\sqlite3.exe"

REM Move to the repo root (the folder above this one), so relative paths work.
cd /d "%~dp0.."

%SQLITE% db\ghg_capstone_project.db ".read load/load_raw_data.sql"

echo.
echo Done. Compare the row counts above with docs\loading_raw_data.md.
pause
