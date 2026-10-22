@echo off
REM Rebuilds db\ghg_capstone_project.db from scratch, from the raw CSV files to the clean tables:
REM   1. load\load_raw_data.sql: drops and recreates every table, then loads the raw and reference CSVs
REM   2. load\clean_data.sql:    runs the cleaning scripts in sql\ in order, with foreign keys enforced
REM Close any program that has the database open first (it locks the file). Then double-click this file.

REM Change this to where sqlite3.exe is on your computer:
set SQLITE="C:\Users\rodne\sqlite\sqlite3.exe"

REM Move to the repo root (the folder above this one), so relative paths work.
cd /d "%~dp0.."

echo Step 1 of 2: loading raw and reference data...
%SQLITE% db\ghg_capstone_project.db ".read load/load_raw_data.sql"
if errorlevel 1 goto failed

echo.
echo Step 2 of 2: running the cleaning scripts...
%SQLITE% db\ghg_capstone_project.db ".read load/clean_data.sql"
if errorlevel 1 goto failed

echo.
echo Done. Compare the row counts above with docs\loading_raw_data.md.
pause
exit /b 0

:failed
echo.
echo STOPPED: the last "Running" line above is the script that failed, and the error gives the line number. Fix it and run this again.
pause
exit /b 1
