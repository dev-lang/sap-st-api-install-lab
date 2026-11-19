@echo off
setlocal

if "%~1"=="" (
    echo Uso: %~nx0 ^<SID^>
    echo Ejemplo: %~nx0 BAS
    exit /b 1
)

set SID=%~1
set BACKUP_DIR=C:\backup-SYB

if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

rem --- Timestamp YYYYMMDD_HHMMSS con PowerShell (wmic ya no existe en Windows 11) ---
set TIMESTAMP=
for /f %%I in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set TIMESTAMP=%%I
if "%TIMESTAMP%"=="" (
    echo No se pudo armar el timestamp. No se hace el dump.
    pause
    exit /b 1
)

set DUMPFILE=%BACKUP_DIR%\%SID%_%TIMESTAMP%.dmp
set LOGFILE=%BACKUP_DIR%\%SID%_%TIMESTAMP%_log.txt
set SQLFILE=%BACKUP_DIR%\_dump_%TIMESTAMP%.sql
set FLAG=%BACKUP_DIR%\_dump_%TIMESTAMP%.fin

rem --- Contrasena de sapsa: se pide al correr, no queda en el script ---
set /p SAPSA_PW=Contrasena de sapsa:

cd /d C:\sybase\%SID%\OCS-15_0\bin
set SYBASE=C:\sybase\%SID%
set SYBASE_OCS=OCS-15_0
set PATH=%SYBASE%\%SYBASE_OCS%\dll;%SYBASE%\%SYBASE_OCS%\bin;%PATH%

> "%SQLFILE%" (
    echo dump database %SID% to '%DUMPFILE%'
    echo go
)

rem --- El dump corre en segundo plano; al terminar crea el archivo .fin ---
start "" /b cmd /c "isql -Usapsa -P%SAPSA_PW% -S%SID% -X -i %SQLFILE% -o %LOGFILE% & echo fin> %FLAG%"
set SAPSA_PW=

rem --- Barra de progreso: lee el % que informa el Backup Server en el log ---
setlocal EnableDelayedExpansion
set /a SEG=0
set N=0

:loop
timeout /t 5 /nobreak >nul
set /a SEG+=5

set PCT=
for /f "tokens=2 delims=()" %%P in ('findstr /c:"DUMPED" "%LOGFILE%" 2^>nul') do set PCT=%%P
if defined PCT set N=!PCT:%%=!

set MB=0
set SZ=
if exist "%DUMPFILE%" for %%F in ("%DUMPFILE%") do set SZ=%%~zF
if defined SZ set MB=!SZ:~0,-6!
if "!MB!"=="" set MB=0

set /a FILL=N/5
set BAR=
for /l %%i in (1,1,20) do (
    if %%i leq !FILL! (set BAR=!BAR!#) else (set BAR=!BAR!.)
)

set /a MIN=SEG/60
set /a SS=SEG%%60

cls
echo Dump de %SID% en curso
echo Archivo: %DUMPFILE%
echo.
if defined PCT (
    echo [!BAR!] !N!%%
) else (
    echo [....................] esperando el primer aviso de progreso
)
echo Escrito: !MB! MB    Tiempo: !MIN! min !SS! s
echo.
echo No cierres esta ventana.

if not exist "%FLAG%" goto loop
endlocal

del "%SQLFILE%" >nul 2>&1
del "%FLAG%" >nul 2>&1

echo.
echo Dump: %DUMPFILE%
echo Log : %LOGFILE%
echo.
findstr /i /c:"DUMP is complete" "%LOGFILE%" >nul && (
    echo OK: el log dice DUMP is complete.
) || (
    echo ATENCION: el log no dice DUMP is complete. Revisalo.
    type "%LOGFILE%"
)
endlocal
pause
