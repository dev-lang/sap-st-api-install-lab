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

set TIMESTAMP=
for /f %%I in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set TIMESTAMP=%%I
if "%TIMESTAMP%"=="" (
    echo No se pudo armar el timestamp. No se hace el dump.
    pause
    exit /b 1
)

set DUMP_TOOLS=%BACKUP_DIR%\saptools_%SID%_%TIMESTAMP%.dmp
set DUMP_MASTER=%BACKUP_DIR%\master_%SID%_%TIMESTAMP%.dmp
set LOGFILE=%BACKUP_DIR%\saptools_master_%SID%_%TIMESTAMP%_log.txt
set SQLFILE=%BACKUP_DIR%\_dump_sys_%TIMESTAMP%.sql

set /p SAPSA_PW=Contrasena de sapsa:

cd /d C:\sybase\%SID%\OCS-15_0\bin
set SYBASE=C:\sybase\%SID%
set SYBASE_OCS=OCS-15_0
set PATH=%SYBASE%\%SYBASE_OCS%\dll;%SYBASE%\%SYBASE_OCS%\bin;%PATH%

> "%SQLFILE%" (
    echo dump database saptools to '%DUMP_TOOLS%'
    echo go
    echo dump database master to '%DUMP_MASTER%'
    echo go
)

echo Haciendo dump de saptools y master...
isql -Usapsa -P%SAPSA_PW% -S%SID% -X -i "%SQLFILE%" -o "%LOGFILE%"
set SAPSA_PW=
del "%SQLFILE%" >nul 2>&1

set OKS=0
for /f %%C in ('findstr /i /c:"DUMP is complete" "%LOGFILE%" ^| find /c /v ""') do set OKS=%%C

echo.
echo saptools: %DUMP_TOOLS%
echo master  : %DUMP_MASTER%
echo Log     : %LOGFILE%
echo.
if "%OKS%"=="2" (
    echo OK: los dos dumps dicen DUMP is complete.
) else (
    echo ATENCION: se esperaban 2 "DUMP is complete" y hay %OKS%. Revisa el log.
    type "%LOGFILE%"
)
endlocal
pause
