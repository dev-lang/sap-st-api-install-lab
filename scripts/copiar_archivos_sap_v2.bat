@echo off
setlocal

if "%~1"=="" (
    echo Uso: %~nx0 ^<SID^>
    echo Ejemplo: %~nx0 BAS
    exit /b 1
)

set SID=%~1
set BACKUP_DIR=C:\backup-SYB

set TIMESTAMP=
for /f %%I in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set TIMESTAMP=%%I
if "%TIMESTAMP%"=="" (
    echo No se pudo armar el timestamp.
    pause
    exit /b 1
)

set DEST=%BACKUP_DIR%\archivos_%SID%_%TIMESTAMP%
mkdir "%DEST%"

rem --- Rutas via el share sapmnt: funcionan sin importar en que disco este \usr\sap ---
set SAPMNT=\\%COMPUTERNAME%\sapmnt
set BUFFER=%SAPMNT%\trans\buffer\%SID%
set PROFILE_DIR=%SAPMNT%\%SID%\SYS\profile
rem En instalaciones SAP el .cfg suele estar en la raiz de C:\sybase\<SID>
set SYBCFG=C:\sybase\%SID%\%SID%.cfg
if not exist "%SYBCFG%" set SYBCFG=C:\sybase\%SID%\ASE-15_0\%SID%.cfg
set SQLINI=C:\sybase\%SID%\ini\sql.ini

set ERRORES=0

echo Copiando buffer de transporte...
if exist "%BUFFER%" (
    copy /y "%BUFFER%" "%DEST%\buffer_%SID%" >nul || set ERRORES=1
) else (
    echo   No se encontro %BUFFER%
    set ERRORES=1
)

echo Copiando perfiles...
if exist "%PROFILE_DIR%" (
    xcopy /e /i /q /y "%PROFILE_DIR%" "%DEST%\profile" >nul || set ERRORES=1
) else (
    echo   No se encontro %PROFILE_DIR%
    set ERRORES=1
)

echo Copiando configuracion de Sybase...
if exist "%SYBCFG%" (
    copy /y "%SYBCFG%" "%DEST%\" >nul || set ERRORES=1
) else (
    echo   No se encontro %SYBCFG%
    set ERRORES=1
)
if exist "%SQLINI%" (
    copy /y "%SQLINI%" "%DEST%\" >nul || set ERRORES=1
) else (
    echo   No se encontro %SQLINI%
    set ERRORES=1
)

echo.
echo Copia en: %DEST%
dir /b "%DEST%"
echo.
if "%ERRORES%"=="0" (
    echo OK: se copio todo.
) else (
    echo ATENCION: algo no se copio. Revisa los mensajes de arriba.
)
endlocal
pause
