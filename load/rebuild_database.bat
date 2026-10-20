@echo off
REM Rebuilds db\ghg_capstone_project.db from scratch:
REM   1. drops and recreates every raw table, raw reference table and clean table (including the ref_ tables)
REM   2. loads every source CSV in data\ into its raw_ table
REM   3. loads the reference CSVs in data\reference\factors\ into their raw_ and ref_ tables
REM Clean tables are emptied by the rebuild, so rerun the cleaning scripts in sql\ afterwards.
REM Close any program that has the database open first (it locks the file). Then double-click this file.

REM Change this to where sqlite3.exe is on your computer:
set SQLITE="C:\Users\rodne\sqlite\sqlite3.exe"

REM Move to the repo root (the folder above this one), so relative paths work.
cd /d "%~dp0.."

%SQLITE% db\ghg_capstone_project.db ".read load/load_raw_data.sql"

echo.
echo Done. Compare the row counts above with docs\loading_raw_data.md.
pause
