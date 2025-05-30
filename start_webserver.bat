@echo off
where node >nul 2>&1
if errorlevel 1 (
    echo Node.js er ikke installeret!
    pause
    exit /b
)
cd /d C:\IT-Projekt\web
node server.js
pause
