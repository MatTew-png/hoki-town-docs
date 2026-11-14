@echo off
chcp 65001 >nul
title [HOKI TOWN] Rojo Server Keep-Alive
color 0B

cd /d "C:\Users\_newgen\Documents\antigravity\HOKI TOWN"

echo ================================================================
echo   [HOKI TOWN] ROJO LIVE SERVER
echo ================================================================
echo.
echo Project Directory: %CD%
echo Target Port:       34872
echo Default Project:   default.project.json
echo.

set "ROJO_EXE=C:\Users\_newgen\AppData\Local\Programs\rojo\rojo.exe"
if not exist "%ROJO_EXE%" (
    where rojo >nul 2>&1
    if errorlevel 1 (
        color 0C
        echo [ERROR] ไม่พบไฟล์ rojo.exe ในระบบ
        pause
        exit /b 1
    )
    set "ROJO_EXE=rojo"
)

:ROJO_LOOP
echo ----------------------------------------------------------------
echo [*] กำลังเริ่ม Rojo Server บนพอร์ต 34872...
echo ----------------------------------------------------------------
echo.

"%ROJO_EXE%" serve default.project.json --port 34872

echo.
color 0E
echo [!] Rojo Server หยุดทำงาน
echo [*] กำลังเริ่มใหม่อัตโนมัติใน 3 วินาที...
ping 127.0.0.1 -n 4 >nul
color 0B
goto ROJO_LOOP
