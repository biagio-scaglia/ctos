@echo off
echo ==========================================
echo   CTOS COMPANION - DESKTOP DASHBOARD
echo ==========================================
echo.

REM Start backend
echo [1/2] Avvio backend FastAPI...
cd /d "%~dp0backend"
start "CTOS Backend" cmd /k "pip install -r requirements.txt -q && uvicorn main:app --reload --port 8000"

timeout /t 3 /nobreak > nul

REM Start frontend
echo [2/2] Avvio frontend Vue...
cd /d "%~dp0frontend"
start "CTOS Frontend" cmd /k "npm install && npm run dev"

timeout /t 4 /nobreak > nul

echo.
echo Dashboard disponibile su: http://localhost:5173
echo Backend API su:           http://localhost:8000
echo.
start http://localhost:5173
