@echo off
chcp 65001 >nul
title ghost-coder
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0ghost-coder.ps1"
pause
