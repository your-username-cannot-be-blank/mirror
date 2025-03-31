::by Ori
chcp 1251
@echo off
title Тест скорости и пропускной способности

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
set /P url="Введите URL для тестирования: "
if not defined url (goto USERINPUT)

set "url=%url:https://=%"
set "url=%url:http://=%"
for /F "tokens=1 delims=/" %%n in ("%url%") do set url=%%n
set "url=https://%url%"

cls

echo.
echo ^> Проверка соединения с %url%
echo.
curl -sSo NUL -m 2 -w "\nIP ресурса: %%{remote_ip}\nURL перенаправления: %%{redirect_url}\n\nВерсия HTTP: %%{http_version}\n\n\nВремя - Резолвинг DNS:\t%%{time_namelookup} микросекунд\nВремя - Соединение:\t%%{time_connect} микросекунд\nВремя - Рукопожатие:\t%%{time_appconnect} микросекунд\n\nВремя - Общее:\t\t%%{time_total} микросекунд\n\nДанных получено в хедере: %%{size_header} байт\n\n\n" %url%
if not %ERRORLEVEL%==0 (set FAILLEVEL=2)
echo = Сертификаты =
echo.
for /F "tokens=1,2* delims=:" %%i in ('curl -so NUL -m 1 -w "%%{certs}\n" %url%') do ((if "%%i"=="Subject" (echo Субъект: %%j)) && (if "%%i"=="Issuer" ((echo Издатель: %%j) && echo.)))
echo.
if %FAILLEVEL%==2 ((echo Тест провален) && (goto END))
echo Тест пройден
echo.

echo ------------------------------------------
echo.
echo ^> Проверка QUIC соединения с %url%
echo.
curl -sSo NUL -m 2 --http3-only -w "\nIP ресурса: %%{remote_ip}\nURL перенаправления: %%{redirect_url}\n\nВерсия HTTP: %%{http_version}\n\n\nВремя - Резолвинг DNS:\t%%{time_namelookup} микросекунд\nВремя - Соединение:\t%%{time_connect} микросекунд\nВремя - Рукопожатие:\t%%{time_appconnect} микросекунд\n\nВремя - Общее:\t\t%%{time_total} микросекунд\n\nДанных получено в хедере: %%{size_header} байт\n\n\n" %url%
if %ERRORLEVEL%==0 (echo Тест пройден) else (if %ERRORLEVEL%==95 (echo Тест пройден) else ((set FAILLEVEL=1) && (echo Тест провален)))
echo.

echo ------------------------------------------
echo.
echo ^> Тест пропускной способности с %connect_to_url% и SNI от %url%; объем передачи: %volume_to_transfer%МБ
echo.
set speed=0
for /F %%i in ('curl -ko NUL -m %time_to_transfer% --connect-to ::%connect_to_url% %url%/%volume_to_transfer%MB -w "%%{speed_download}\n\n"') do set speed=%%i
set /A speed=%speed%/1024
echo.
echo Средняя пропускная способность, по оценке curl: %speed%KB/s
set speed=
echo.

echo ------------------------------------------
echo.
echo ^> Тест стабильности соединения с %url%, %attempts% попыток
echo.
set successes=0
set counter=%attempts%
:LOOP
for /F %%g in ('curl -so NUL -m 1 %url% -w "%%{response_code}\n"') do set code=%%g
echo Код ответа: %code%
if not %code%==000 (set /A successes=%successes%+1)
set /A counter=%counter%-1
if not %counter%==0 (goto LOOP)
echo.
echo Удачных соединений: %successes% из %attempts%
set successes=
set counter=
echo.

if %FAILLEVEL%==1 (goto SKIPQUIC1)
echo ------------------------------------------
echo.
echo ^> Тест стабильности QUIC соединения с %url%, %attempts% попыток
echo.
set successes=0
set counter=%attempts%
:LOOP_QUIC
for /F %%g in ('curl -so NUL --http3-only -m 1 %url% -w "%%{response_code}\n"') do set code=%%g
echo Код ответа: %code%
if not %code%==000 (set /A successes=%successes%+1)
set /A counter=%counter%-1
if not %counter%==0 (goto LOOP_QUIC)
echo.
echo Удачных соединений: %successes% out of %attempts%
set successes=
set counter=
echo.

:SKIPQUIC1
echo ------------------------------------------
echo.
echo ^> Тест стабильности соединения с %url%, 10 попыток параллельно
echo.
curl -sSZm 3 --parallel-immediate --parallel-max 10 %url% %url% %url% %url% %url% %url% %url% %url% %url% %url% > NUL
echo.
if %ERRORLEVEL%==0 (echo Тест пройден) else (echo Тест провален)

if %FAILLEVEL%==1 (goto END)
echo.
echo ------------------------------------------
echo.
echo ^> Тест стабильности QUIC соединения с %url%, 10 попыток параллельно
echo.
curl -sSZm 3 --http3-only --parallel-immediate --parallel-max 10 %url% %url% %url% %url% %url% %url% %url% %url% %url% %url% > NUL
echo.
if %ERRORLEVEL%==0 (echo Тест пройден) else (if %ERRORLEVEL%==95 (echo Тест пройден) else (echo Тест провален))

:END
echo.
echo ------------------------------------------
echo.
set url=
choice /C YN /M "Ещё один тест?"
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
echo Curl устарел.
echo Скачайте актуальную версию: https://curl.se/
echo.
echo Нажмите любую кнопку для выхода...
pause>NUL
exit /b