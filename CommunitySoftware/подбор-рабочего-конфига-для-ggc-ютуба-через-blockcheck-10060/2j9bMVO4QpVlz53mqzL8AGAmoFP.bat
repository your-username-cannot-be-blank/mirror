@echo off
title IpBlockChecker
color f0
SetLocal EnableExtensions EnableDelayedExpansion
:restart
set ipList=
set url=
for %%i in (S1 S2 P1 P2) do set "curlCode%%i="
set "$dnsProviders=1.1.1.1 4.2.2.1 8.26.56.26 94.247.43.254"
set "$domen=iana.org"
set "$logFile=%~dps0%~n0.log"
set /P url=Insert site URL and press Enter:
if not defined url goto :restart
set "domen=%url:http://=%"
set "domen=%domen:https://=%"
@echo Checking website blocking by IP...
call :GetSystemIp sysIP "%domen%"
if defined sysIP (	
	call :GetCurlCode curlCodeS1 "%domen%" "%sysIP%"
	if !curlCodeS1!==0 (
		call :ShowMessageAndRestart "%domen% is NOT blocked by system IP=%sysIP%")
	call :GetCurlCode curlCodeS2 "%$domen%" "%sysIP%"
	if !curlCodeS2!==0 (
		call :ShowMessageAndRestart "%domen% is NOT blocked by system IP=%sysIP%"))
for %%i in (%$dnsProviders%) do (
	call :GetDnsProviderIp dpIp "%domen%" "%%i"
	if defined dpIp (
		if not "!dpIp!"=="%sysIP%" (
			@echo !ipList!|findstr "!dpIp!">nul
			if !errorLevel!==1 (
				set "ipList=!ipList! !dpIp!"
				call :GetCurlCode curlCodeP1 "%domen%" "!dpIp!"
				if !curlCodeP1!==0 (
					call :ShowMessageAndRestart "%domen% is blocked by system IP=%sysIP%. Add in %windir%\System32\drivers\etc\hosts redirection to working IP: !dpIp! %domen%")
				call :GetCurlCode curlCodeP2 "%$domen%" "!dpIp!"
				if !curlCodeP2!==0 (
					call :ShowMessageAndRestart "%domen% is blocked by system IP=%sysIP%. Add in %windir%\System32\drivers\etc\hosts redirection to working IP: !dpIp! %domen%")))))
if not defined ipList (
	if not defined sysIP (
		call :ShowMessageAndRestart "Error: Can't find any IP for %domen%. Try to check any subdomens of %domen%"))
for %%i in (S1 S2 P1 P2) do (
	if "!curlCode%%i!"=="35" (
		call :ShowMessageAndRestart "Probably, %domen% is NOT blocked by system IP=%sysIP%, but there are some errors. Try different gdpi settings."))	
call :ShowMessageAndRestart "%domen% is blocked by system IP=%sysIP%. Can't find working IP. Use DoH in your browser!"
EndLocal DisableDelayedExpansion

:GetCurlCode
rem Если вернул 0, то ip незаблокирован, если иной код, то нужно разбираться
SetLocal EnableDelayedExpansion
set site=%~2
set ip=%~3
curl -ks -m 2 --connect-to %site%::[%ip%]:443 --tlsv1.3 -A Mozilla -I https://%site% -o nul 2>nul
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

:GetDnsProviderIp
SetLocal EnableDelayedExpansion
set site=%~2	
set dnsProvider=%~3
for /f "skip=4 tokens=1,* delims=: " %%i in ('nslookup %site% %dnsProvider% 2^>nul') do (
	@echo %%j|findstr /R /C:"\<[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*\>">nul && set "IP=%%j")
EndLocal DisableDelayedExpansion & (
    set "%~1=%IP%")
exit /b

:ShowMessageAndRestart
SetLocal EnableDelayedExpansion
set text=%~1
cls
@echo %text%
@echo %text%>>"%$logFile%"
EndLocal DisableDelayedExpansion
pause
cls
goto :restart