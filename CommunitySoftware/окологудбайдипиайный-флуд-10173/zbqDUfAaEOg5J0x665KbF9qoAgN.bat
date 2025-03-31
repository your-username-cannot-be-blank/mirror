::by Ori
chcp 1251
@echo off
title ���� �������� � ���������� �����������

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
set /P url="������� URL ��� ������������: "
if not defined url (goto USERINPUT)

set "url=%url:https://=%"
set "url=%url:http://=%"
for /F "tokens=1 delims=/" %%n in ("%url%") do set url=%%n
set "url=https://%url%"

cls

echo.
echo ^> �������� ���������� � %url%
echo.
curl -sSo NUL -m 2 -w "\nIP �������: %%{remote_ip}\nURL ���������������: %%{redirect_url}\n\n������ HTTP: %%{http_version}\n\n\n����� - ��������� DNS:\t%%{time_namelookup} �����������\n����� - ����������:\t%%{time_connect} �����������\n����� - �����������:\t%%{time_appconnect} �����������\n\n����� - �����:\t\t%%{time_total} �����������\n\n������ �������� � ������: %%{size_header} ����\n\n\n" %url%
if not %ERRORLEVEL%==0 (set FAILLEVEL=2)
echo = ����������� =
echo.
for /F "tokens=1,2* delims=:" %%i in ('curl -so NUL -m 1 -w "%%{certs}\n" %url%') do ((if "%%i"=="Subject" (echo �������: %%j)) && (if "%%i"=="Issuer" ((echo ��������: %%j) && echo.)))
echo.
if %FAILLEVEL%==2 ((echo ���� ��������) && (goto END))
echo ���� �������
echo.

echo ------------------------------------------
echo.
echo ^> �������� QUIC ���������� � %url%
echo.
curl -sSo NUL -m 2 --http3-only -w "\nIP �������: %%{remote_ip}\nURL ���������������: %%{redirect_url}\n\n������ HTTP: %%{http_version}\n\n\n����� - ��������� DNS:\t%%{time_namelookup} �����������\n����� - ����������:\t%%{time_connect} �����������\n����� - �����������:\t%%{time_appconnect} �����������\n\n����� - �����:\t\t%%{time_total} �����������\n\n������ �������� � ������: %%{size_header} ����\n\n\n" %url%
if %ERRORLEVEL%==0 (echo ���� �������) else (if %ERRORLEVEL%==95 (echo ���� �������) else ((set FAILLEVEL=1) && (echo ���� ��������)))
echo.

echo ------------------------------------------
echo.
echo ^> ���� ���������� ����������� � %connect_to_url% � SNI �� %url%; ����� ��������: %volume_to_transfer%��
echo.
set speed=0
for /F %%i in ('curl -ko NUL -m %time_to_transfer% --connect-to ::%connect_to_url% %url%/%volume_to_transfer%MB -w "%%{speed_download}\n\n"') do set speed=%%i
set /A speed=%speed%/1024
echo.
echo ������� ���������� �����������, �� ������ curl: %speed%KB/s
set speed=
echo.

echo ------------------------------------------
echo.
echo ^> ���� ������������ ���������� � %url%, %attempts% �������
echo.
set successes=0
set counter=%attempts%
:LOOP
for /F %%g in ('curl -so NUL -m 1 %url% -w "%%{response_code}\n"') do set code=%%g
echo ��� ������: %code%
if not %code%==000 (set /A successes=%successes%+1)
set /A counter=%counter%-1
if not %counter%==0 (goto LOOP)
echo.
echo ������� ����������: %successes% �� %attempts%
set successes=
set counter=
echo.

if %FAILLEVEL%==1 (goto SKIPQUIC1)
echo ------------------------------------------
echo.
echo ^> ���� ������������ QUIC ���������� � %url%, %attempts% �������
echo.
set successes=0
set counter=%attempts%
:LOOP_QUIC
for /F %%g in ('curl -so NUL --http3-only -m 1 %url% -w "%%{response_code}\n"') do set code=%%g
echo ��� ������: %code%
if not %code%==000 (set /A successes=%successes%+1)
set /A counter=%counter%-1
if not %counter%==0 (goto LOOP_QUIC)
echo.
echo ������� ����������: %successes% out of %attempts%
set successes=
set counter=
echo.

:SKIPQUIC1
echo ------------------------------------------
echo.
echo ^> ���� ������������ ���������� � %url%, 10 ������� �����������
echo.
curl -sSZm 3 --parallel-immediate --parallel-max 10 %url% %url% %url% %url% %url% %url% %url% %url% %url% %url% > NUL
echo.
if %ERRORLEVEL%==0 (echo ���� �������) else (echo ���� ��������)

if %FAILLEVEL%==1 (goto END)
echo.
echo ------------------------------------------
echo.
echo ^> ���� ������������ QUIC ���������� � %url%, 10 ������� �����������
echo.
curl -sSZm 3 --http3-only --parallel-immediate --parallel-max 10 %url% %url% %url% %url% %url% %url% %url% %url% %url% %url% > NUL
echo.
if %ERRORLEVEL%==0 (echo ���� �������) else (if %ERRORLEVEL%==95 (echo ���� �������) else (echo ���� ��������))

:END
echo.
echo ------------------------------------------
echo.
set url=
choice /C YN /M "��� ���� ����?"
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
echo Curl �������.
echo �������� ���������� ������: https://curl.se/
echo.
echo ������� ����� ������ ��� ������...
pause>NUL
exit /b