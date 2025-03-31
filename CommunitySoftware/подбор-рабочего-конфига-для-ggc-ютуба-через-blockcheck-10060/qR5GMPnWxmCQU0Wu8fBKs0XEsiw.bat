@echo off
color f0
SetLocal EnableExtensions EnableDelayedExpansion
:repeat
cls
SET /P aURL=Enter site URL:
if not defined aURL goto :repeat
call :GetSystemIp sysIP "%aURL%"
call :CheckIpBlock curlCode "%sysIP%"
if %curlCode% == 0 (
	@echo "%aURL%" is NOT blocked by IP ...
	pause>nul
	cls
	goto :repeat)
set "dohIPList=77.88.8.8 76.76.2.22 194.36.144.87"
for %%i in (%dohIPList%) do (
	call :GetDohIp dohIP "%aURL%" "%%i"
	call :CheckIpBlock curlCode "!dohIP!"
	if !curlCode! == 0 (
	@echo Working IP for "%aURL%" is !dohIP!
	pause>nul
	cls
	goto :repeat)
)
if !curlCode! == 28 (
	@echo Sorry, can't find working IP for %aURL%. Try to enable DoH in your browser or change it!
) else (
	@echo Probably, %aURL% is NOT blocked by IP, but has some problems with certificates...)	
pause>nul
cls
goto :repeat
EndLocal DisableDelayedExpansion

:CheckIpBlock
rem Если вернул 0, то ip незаблокирован, если 28 - заблокирован, если иной код, то нужно разбираться
SetLocal EnableDelayedExpansion
set ip=%~2
curl -ks --connect-to ya.ru::[%ip%]:443 -ISs -A Mozilla --max-time 2 --tlsv1.3 --tls-max 1.3 https://ya.ru -o nul 2>nul
set code=%errorLevel%
EndLocal DisableDelayedExpansion & (
    set "%~1=%code%")
exit /b	  

:GetSystemIp
SetLocal EnableDelayedExpansion		
set site=%~2
for /f "tokens=2 delims=[]" %%a in ('ping -4 -n 1 %site% ^| findstr [') do (
	set IP=%%a)
EndLocal DisableDelayedExpansion & (
    set "%~1=%IP%")
exit /b

:GetDohIp
SetLocal EnableDelayedExpansion
set site=%~2	
set doh=%~3
for /f "skip=5 tokens=2 delims=: " %%i in ('nslookup %site% %doh% 2^>nul') do (
	set IP=%%i)
EndLocal DisableDelayedExpansion & (
    set "%~1=%IP%")
exit /b