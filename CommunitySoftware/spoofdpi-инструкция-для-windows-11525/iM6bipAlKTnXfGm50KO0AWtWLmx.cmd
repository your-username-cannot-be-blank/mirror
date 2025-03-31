@echo off
title SpoofDpi
set exe=spoofdpi-windows-amd64.exe
set ip=127.0.0.1
set port=18082
set window-size=1
set dns=1.1.1.1
set cmdLine=%exe% -addr %ip% -port %port% -window-size %window-size% -dns-addr %dns%
taskkill /IM "%exe%" /F 1>nul 2>nul
%cmdLine% -debug
pause