::by Ori
@echo off
chcp 65001
title ECH Support Tester
cls

setlocal EnableDelayedExpansion

echo Testing connectivity...
for /F "tokens=*" %%i in ('curl -skm 2 -o NUL -w "%%{response_code}" "https://dns.google"') do (set "conn=%%i")
if !conn!==000 (
	echo No connection. Make sure that Curl is present and not blocked by firewall.
	goto EOF
)

cls

set /P "website=Input URL to test: "
echo Parsing user input...
set "website=!website:https://=!"
set "website=!website:http://=!"
for /F "tokens=1 delims=/" %%i in ("!website!") do (set "website=%%i")

echo Making DNS request...
for /F "tokens=*" %%i in ('curl -skm 2 "https://dns.google/resolve?name=!website!&type=HTTPS"') do (set "response=%%i")

echo Parsing response...
set "response=!response:,= !"
set "response=!response:[= !"
set "response=!response:{= !"
set "response=!response:(= !"
set "response=!response:]= !"
set "response=!response:}= !"
set "response=!response:)= !"
set ^"response=!response:"= !^"

set bufnext=false
set echValue=
for %%i in (!response!) do (
	echo %%i
	if !bufnext!==true (
				echo ECH value found
				set "echValue=%%i"
				goto BREAK
			)
	if "%%i" == "ech" (set bufnext=true)
)
:BREAK

echo Showcasing result...
cls
if defined echValue (
	echo ECH are supported by '!website!': !echValue!
) else (
	echo ECH aren't supported by '!website!' ^:^(
)

:EOF
endlocal

echo.
echo Press any button to exit...
pause>NUL
title %comspec%
exit /b