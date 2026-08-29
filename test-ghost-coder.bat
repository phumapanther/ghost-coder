@echo off
chcp 65001 >nul
title ghost-coder (test - start now)
echo ทดสอบ: ไม่ต้องรอ 3 นาที จะเริ่มพิมทันที — อย่าแตะเมาส์/คีย์บอร์ดถ้าอยากดูผีทำงาน
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0ghost-coder.ps1" -TestNow
pause
