@echo off
rem Starts the launcher in the background (no window).
start "" powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "%~dp0launcher.ps1"
