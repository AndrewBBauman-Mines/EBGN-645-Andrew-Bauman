@echo off
REM Runs the Milestone 3 model on this computer's GAMS license and builds the figures.
REM Everything printed here is also saved to run_log.txt for Claude to read back.
cd /d "%~dp0"
set LOG=run_log.txt
echo Milestone 3 run started %DATE% %TIME% > %LOG%

REM ---- find GAMS -------------------------------------------------------------
set GAMSEXE=
where gams >nul 2>nul && set GAMSEXE=gams
if "%GAMSEXE%"=="" for /d %%D in ("C:\GAMS\*") do if exist "%%D\gams.exe" set GAMSEXE="%%D\gams.exe"
if "%GAMSEXE%"=="" for /d %%D in ("C:\GAMS\win64\*") do if exist "%%D\gams.exe" set GAMSEXE="%%D\gams.exe"
if "%GAMSEXE%"=="" (
  echo ERROR: could not find gams.exe on PATH or under C:\GAMS >> %LOG%
  echo ERROR: could not find gams.exe. See run_log.txt
  pause
  exit /b 1
)
echo Using GAMS: %GAMSEXE% >> %LOG%

REM ---- run the model (full horizon to 2065) -----------------------------------
echo Running GAMS, this takes under a minute...
%GAMSEXE% run_all.gms --maxage=10 lo=3 >> %LOG% 2>&1
echo GAMS exit code: %ERRORLEVEL% >> %LOG%
findstr /C:"MODEL STATUS" /C:"*** Error" /C:"licens" /C:"License" run_all.lst > status_summary.txt 2>nul

REM ---- figures and tables -----------------------------------------------------
echo Building figures...
python make_figures.py >> %LOG% 2>&1
if errorlevel 1 (
  echo Python figures failed, trying to install pandas and matplotlib >> %LOG%
  python -m pip install --user pandas matplotlib >> %LOG% 2>&1
  python make_figures.py >> %LOG% 2>&1
)
echo Python exit code: %ERRORLEVEL% >> %LOG%
echo Finished %DATE% %TIME% >> %LOG%
echo.
echo Done. You can close this window and tell Claude it finished.
pause
