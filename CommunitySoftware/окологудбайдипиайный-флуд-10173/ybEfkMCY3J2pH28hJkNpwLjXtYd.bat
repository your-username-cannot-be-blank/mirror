::by Ori
@echo off
title Connection and Bandwidth Test

for /F "tokens=1,2 delims= " %%i in ('curl -V') do (if "%%i"=="curl" set version=%%j)
for /F "tokens=1,2 delims=." %%i in ("%version%") do (set MajorVersion=%%i && set MinorVersion=%%j)
if %MajorVersion% LSS 8 (goto OUTDATED)
if %MinorVersion% LSS 10 (goto OUTDATED)

set "connect_to_url=speedtest.selectel.ru"
set volume_to_transfer=10
set attempts=10

set /A time_to_transfer=%volume_to_transfer%/2

:USERINPUT

::FAILLEVEL 0=allgreen;1=QUIC fail;2=total fail
set FAILLEVEL=0

cls
echo.
set /P url="Input URL to test: "
if not defined url (goto USERINPUT)

set "url=%url:https://=%"
set "url=%url:http://=%"
for /F "tokens=1 delims=/" %%n in ("%url%") do set url=%%n
set "url=https://%url%"

cls

echo.
echo ^> Testing connectivity with %url%
echo.
curl -sSo NUL -m 2 -w "\nRemote IP: %%{remote_ip}\nRedirect URL: %%{redirect_url}\n\nHTTP version: %%{http_version}\n\n\nTime - DNS Lookup:\t%%{time_namelookup} microseconds\nTime - Connection:\t%%{time_connect} microseconds\nTime - Handshake:\t%%{time_appconnect} microseconds\n\nTime - Total:\t\t%%{time_total} microseconds\n\nData received in header: %%{size_header} bytes\n\n\n" %url%
if not %ERRORLEVEL%==0 (set FAILLEVEL=2)
echo = Certificates =
echo.
for /F "tokens=1,2* delims=:" %%i in ('curl -so NUL -m 1 -w "%%{certs}\n" %url%') do ((if "%%i"=="Subject" (echo Subject: %%j)) && (if "%%i"=="Issuer" ((echo Issuer: %%j) && echo.)))
echo.
if %FAILLEVEL%==2 ((echo Test failed) && (goto END))
echo Test passed
echo.

echo ------------------------------------------
echo.
echo ^> Testing QUIC connectivity with %url%
echo.
curl -sSo NUL -m 2 --http3-only -w "\nRemote IP: %%{remote_ip}\nRedirect URL: %%{redirect_url}\n\nHTTP version: %%{http_version}\n\n\nTime - DNS Lookup:\t%%{time_namelookup} microseconds\nTime - Connection:\t%%{time_connect} microseconds\nTime - Handshake:\t%%{time_appconnect} microseconds\n\nTime - Total:\t\t%%{time_total} microseconds\n\nData received in header: %%{size_header} bytes\n\n\n" %url%
if %ERRORLEVEL%==0 (echo Test passed) else (if %ERRORLEVEL%==95 (echo Test passed) else ((set FAILLEVEL=1) && (echo Test failed)))
echo.

echo ------------------------------------------
echo.
echo ^> Testing channel bandwidth using %connect_to_url% and SNI of %url%; volume to transfer: %volume_to_transfer%MB
echo.
set speed=0
for /F %%i in ('curl -ko NUL -m %time_to_transfer% --connect-to ::%connect_to_url% %url%/%volume_to_transfer%MB -w "%%{speed_download}\n\n"') do set speed=%%i
set /A speed=%speed%/1024
echo.
echo Average channel bandwidth estimated by curl: %speed%KB/s
set speed=
echo.

echo ------------------------------------------
echo.
echo ^> Testing connection stability with %url%, %attempts% attempts
echo.
set successes=0
set counter=%attempts%
:LOOP
for /F %%g in ('curl -so NUL -m 1 %url% -w "%%{response_code}\n"') do set code=%%g
echo Response code: %code%
if not %code%==000 (set /A successes=%successes%+1)
set /A counter=%counter%-1
if not %counter%==0 (goto LOOP)
echo.
echo Succesful connections: %successes% out of %attempts%
set successes=
set counter=
echo.

if %FAILLEVEL%==1 (goto SKIPQUIC1)
echo ------------------------------------------
echo.
echo ^> Testing QUIC connection stability with %url%, %attempts% attempts
echo.
set successes=0
set counter=%attempts%
:LOOP_QUIC
for /F %%g in ('curl -so NUL --http3-only -m 1 %url% -w "%%{response_code}\n"') do set code=%%g
echo Response code: %code%
if not %code%==000 (set /A successes=%successes%+1)
set /A counter=%counter%-1
if not %counter%==0 (goto LOOP_QUIC)
echo.
echo Succesful connections: %successes% out of %attempts%
set successes=
set counter=
echo.

:SKIPQUIC1
echo ------------------------------------------
echo.
echo ^> Testing connection stability with %url%, 10 attempts in parallel
echo.
curl -sSZm 3 --parallel-immediate --parallel-max 10 %url% %url% %url% %url% %url% %url% %url% %url% %url% %url% > NUL
echo.
if %ERRORLEVEL%==0 (echo Test passed) else (echo Test failed)

if %FAILLEVEL%==1 (goto END)
echo.
echo ------------------------------------------
echo.
echo ^> Testing QUIC connection stability with %url%, 10 attempts in parallel
echo.
curl -sSZm 3 --http3-only --parallel-immediate --parallel-max 10 %url% %url% %url% %url% %url% %url% %url% %url% %url% %url% > NUL
echo.
if %ERRORLEVEL%==0 (echo Test passed) else (if %ERRORLEVEL%==95 (echo Test passed) else (echo Test failed))

:END
echo.
echo ------------------------------------------
echo.
set url=
choice /C YN /M "Another test?"
if %ERRORLEVEL%==1 (goto USERINPUT)

:EOF
set version=
set MajorVersion=
set MinorVersion=
set connect_to_url=
set volume_to_transfer=
set time_to_transfer=
set attempts=
exit /b

:OUTDATED
set version=
set MajorVersion=
set MinorVersion=
echo.
echo Curl outdated.
echo Obtain actual version at https://curl.se/
echo.
echo Press any button to exit...
pause>NUL
exit /b