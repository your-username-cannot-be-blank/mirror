@echo off
title IpBlockChecker
color f0
SetLocal EnableExtensions EnableDelayedExpansion
:restart
set ipList=
set url=
for %%i in (Sys1 Sys2 Prov1 Prov2) do set "curlCode%%i="
set "$dnsProviders=1.1.1.1 4.2.2.1 8.26.56.26 94.247.43.254"
set "$logFile=%~dps0%~n0.log"
set "domen2=iana.org"
set /P url=Insert site URL and press Enter:
if not defined url goto :restart
set "domen=%url:http://=%"
set "domen1=%domen:https://=%"
@echo Checking website blocking by IP...
call :GetSystemIp sysIP "%domen1%"
if defined sysIP (
	for %%n in (1 2) do (
		call :GetCurlCode curlCodeSys%%n "!domen%%n!" "%sysIP%"
		for %%v in (1.2 1.3) do (
			if "!curlCodeSys%%n_%%v!"=="0" (
				call :ShowMessageAndRestart "%domen1% is NOT blocked by system IP=%sysIP%")
			if "!curlCodeSys%%n_%%v!"=="35" (
				call :ShowMessageAndRestart "Probably, %domen1% is NOT blocked by system IP=%sysIP%, but there are some errors. Try different gdpi settings")))
) else (
	call :ShowMessageAndRestart "Error: Can't find system IP for %domen1%. Ping is not working. Try to check any subdomens of %domen1%")
for %%i in (%$dnsProviders%) do (
	call :GetDnsProviderIp dpIp "%domen1%" "%%i"
	if defined dpIp (
		if not "!dpIp!"=="%sysIP%" (
			@echo !ipList!|findstr "!dpIp!">nul
			if !errorLevel!==1 (
				set "ipList=!ipList! !dpIp!"
				for %%n in (1 2) do (
					call :GetCurlCode curlCodeProv%%n "!domen%%n!" "!dpIp!"
					for %%v in (1.2 1.3) do (
						if "!curlCodeProv%%n_%%v!"=="0" (
							call :ShowMessageAndRestart "%domen1% is blocked by system IP=%sysIP%. Add in %windir%\System32\drivers\etc\hosts redirection to working IP: !dpIp! %domen1%")
						if "!curlCodeProv%%n_%%v!"=="35" (
							call :ShowMessageAndRestart "%domen1% is blocked by system IP=%sysIP%. Try to add in %windir%\System32\drivers\etc\hosts redirection to IP: !dpIp! %domen1%. Also try different gdpi settings")))))))
if not defined ipList (
	call :ShowMessageAndRestart "%domen1% is blocked by system IP=%sysIP%. Can't find any other IP. Use DoH in your browser!"
) else (
	call :ShowMessageAndRestart "%domen1% is blocked by system IP=%sysIP%. Can't find working IP. Use DoH in your browser!"
)
EndLocal DisableDelayedExpansion

:GetCurlCode
rem Если вернул 0, то ip незаблокирован, если иной код, то нужно разбираться
SetLocal EnableDelayedExpansion
set site=%~2
set ip=%~3
curl -ks -m 2 --connect-to %site%::[%ip%]:443 --tlsv1.2 -A Mozilla -I https://%site% -o nul 2>nul
set code1.2=%errorLevel%
curl -ks -m 2 --connect-to %site%::[%ip%]:443 --tlsv1.3 -A Mozilla -I https://%site% -o nul 2>nul
set code1.3=%errorLevel%
EndLocal DisableDelayedExpansion & (
    set "%~1_1.2=%code1.2%"
	set "%~1_1.3=%code1.3%")
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