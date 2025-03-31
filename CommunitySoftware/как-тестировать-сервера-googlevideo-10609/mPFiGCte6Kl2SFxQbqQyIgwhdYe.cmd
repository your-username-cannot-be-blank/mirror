@echo off
title Curl {Тест соединения и скорости}

set "connect_to_url=speedtest.selectel.ru"
set volume_to_transfer=10
set attempts=10

:USERINPUT
cls
echo.
set /P url="Введите URL для теста: "
if not defined url (goto USERINPUT)

set "url=%url:https://=%"
set "url=%url:http://=%"
for /F "tokens=1 delims=/" %%n in ("%url%") do set url=%%n
set "url=https://%url%"

cls

echo.
echo ^> Тестируем соединение с %url%
echo.
curl -so NUL -m 2 -w "Lookup time:\t%%{time_namelookup}\nConnect time:\t%%{time_connect}\nAppCon time:\t%%{time_appconnect}\nRedirect time:\t%%{time_redirect}\nPreXfer time:\t%%{time_pretransfer}\nStartXfer time:\t%%{time_starttransfer}\n\nTotal time:\t%%{time_total}\n" %url%
echo.

echo.
echo ^> Тестируем соединение по протоколу QUIC c %url%
echo.
curl -so NUL -m 2 --http3-only -w "Lookup time:\t%%{time_namelookup}\nConnect time:\t%%{time_connect}\nAppCon time:\t%%{time_appconnect}\nRedirect time:\t%%{time_redirect}\nPreXfer time:\t%%{time_pretransfer}\nStartXfer time:\t%%{time_starttransfer}\n\nTotal time:\t%%{time_total}\n" %url%
echo.

echo.
echo ^> Тестируем скорость через %connect_to_url% для сайта %url%; размер файла: %volume_to_transfer%MB
echo.
set speed=0
for /F %%i in ('curl -ko NUL -m 3 --connect-to ::%connect_to_url% %url%/%volume_to_transfer%MB -w "%%{speed_download}\n"') do set speed=%%i
set /A speed=%speed%/1024
echo.
echo Средняя скорость при скачивании через curl: %speed%KB/s
set speed=
echo.

echo.
echo ^> Тестируем стабильность соединения с %url%, %attempts% раз
echo.
set successes=0
set counter=%attempts%
:LOOP
for /F %%g in ('curl -sko NUL -m 1 %url% -w "%%{http_code}\n"') do set code=%%g
echo Response code: %code%
if not %code%==000 (set /A successes=%successes%+1)
set /A counter=%counter%-1
if not %counter%==0 (goto LOOP)
echo.
echo Удачных соединений: %successes% из %attempts%
set successes=
set counter=
echo.

echo.
echo ^> Тестируем стабильность соединения с %url%, 10 раз, параллельно
echo.
curl -sSkZm 3 --parallel-immediate --parallel-max 10 %url% %url% %url% %url% %url% %url% %url% %url% %url% %url% > NUL
if not %ERRORLEVEL%==0 (echo. && echo Тест неудачный) else (echo Тест удачный)
echo.

echo.
set url=
choice /C YN /M "Протестировать другой сайт?"
if %ERRORLEVEL%==1 (goto USERINPUT)

:EOF
set connect_to_url=
set volume_to_transfer=
set attempts=
exit /b
