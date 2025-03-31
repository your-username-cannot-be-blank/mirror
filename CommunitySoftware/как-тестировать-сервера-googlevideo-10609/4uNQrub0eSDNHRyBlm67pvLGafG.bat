::by Ori
chcp 1251
@echo off
cls

::Setting variables
set attempts=10
set "connect_to_url=speedtest.selectel.ru"
set volume_to_transfer=10
set /A time_to_transfer=(%volume_to_transfer%+1)/2
set cluster=0
set "DefaultText=[0m"
set "RedText=[91m"
set "GreenText=[92m"
set "BoldText=[1m"
set "InverseText=[7m"
set customcluster=%*

::Checking Curl version
for /F "tokens=1,2 delims= " %%i in ('curl -V') do (if "%%i"=="curl" set version=%%j)
for /F "tokens=1,2 delims=." %%i in ("%version%") do (set MajorVersion=%%i && set MinorVersion=%%j)
if %MajorVersion% LSS 8 (goto OUTDATED)
if %MinorVersion% LSS 10 (goto OUTDATED)

::Cluster codename search
echo.
echo %InverseText%Looking for cluster codename%DefaultText%
echo.
if not defined customcluster (goto USERINPUTCLUSTER)
:PARSECUSTOMCLUSTER
::Parsing custom cluster codename
for /F "tokens=1 delims=." %%i in ("%customcluster%") do (set "customcluster=%%i")
for /F "tokens=1* delims=-" %%i in ("%customcluster%") do (set "customcluster=%%j")
set "cluster=%customcluster%"
echo %BoldText%Cluster codename:%DefaultText% %cluster%
set "cluster=---%cluster%"
goto PINGING

:USERINPUTCLUSTER
::Custom input by user
set /P customcluster="Input googlevideo URL or press ENTER for auto: "
echo.
if defined customcluster (goto PARSECUSTOMCLUSTER)

::Searching cluster codename
for /F "tokens=3 delims= " %%i in ('curl -sm 2 "https://redirector.googlevideo.com/report_mapping?di=no"') do (set cluster=%%i)
if %cluster%==0 ((echo %RedText%Failure! Cannot establish connection to googlevideo.com to find cluster codename%DefaultText%) && (goto EOF))
echo %BoldText%Cluster codename:%DefaultText% %cluster%
set "cluster=.%cluster%"

:PINGING
::Forming URL list
echo.
echo %InverseText%Forming list of servers%DefaultText%
echo.
set ggcCounter=1
:PINGINGLOOP
set ggcURL=rr%ggcCounter%%cluster%.googlevideo.com
echo %BoldText%Pinging%DefaultText% %ggcURL%...
ping -n 1 -w 2000 %ggcURL% >NUL
if %ERRORLEVEL%==0 ((echo %GreenText%Success%DefaultText%) && (set /A ggcCounter=%ggcCounter%+1) && (echo.) && (goto PINGINGLOOP))
echo %RedText%Failure%DefaultText%
set /A ggcCounter=%ggcCounter%-1

::Testing TCP Connection
echo.
echo %InverseText%Testing connectivity%DefaultText%
echo.
set Counter=1
:TCPCONNLOOP
set "ggcURL=https://rr%counter%%cluster%.googlevideo.com"
echo %BoldText%Testing%DefaultText% %ggcURL%...
curl -sko NUL -m 2 -w "DNS_T: %%{time_namelookup} µs  - Connection_T: %%{time_connect} µs  - Handshake_T: %%{time_appconnect} µs  - Total_T: %%{time_total} µs  - Header: %%{size_header} bytes\n" %ggcURL%
if %ERRORLEVEL%==0 (echo %GreenText%Test passed%DefaultText%) else (echo %RedText%Test failed%DefaultText%)
echo.
set /A Counter=%Counter%+1
if not %Counter% GTR %ggcCounter% (goto TCPCONNLOOP)

::Testing UDP Connection
echo.
echo %InverseText%Testing QUIC connectivity%DefaultText%
echo.
set Counter=1
:UDPCONNLOOP
set "ggcURL=https://rr%counter%%cluster%.googlevideo.com"
echo %BoldText%Testing%DefaultText% %ggcURL%...
curl -sko NUL -m 2 --http3-only -w "DNS_T:%%{time_namelookup} µs - Connection_T: %%{time_connect} µs - Handshake_T: %%{time_appconnect} µs - Total_T: %%{time_total} µs - Header: %%{size_header} bytes\n" %ggcURL%
if %ERRORLEVEL%==0 (echo %GreenText%Test passed%DefaultText%) else (if %ERRORLEVEL%==95 (echo %GreenText%Test passed%DefaultText%) else (echo %RedText%Test failed%DefaultText%))
echo.
set /A Counter=%Counter%+1
if not %Counter% GTR %ggcCounter% (goto UDPCONNLOOP)

::Testing TCP bandwidth
echo.
echo %InverseText%Testing channel bandwidth using %connect_to_url%, transferring %volume_to_transfer%MB%DefaultText%
echo.
set Counter=1
:TCPBANDLOOP
set "ggcURL=https://rr%counter%%cluster%.googlevideo.com"
echo %BoldText%Testing%DefaultText% %ggcURL%...
set speed=0
for /F %%i in ('curl -sko NUL -m %time_to_transfer% --connect-to ::%connect_to_url% %ggcURL%/%volume_to_transfer%MB -w "%%{speed_download}"') do set speed=%%i
set /A speed=%speed%/1024
if %speed% GTR 1000 (set clr=%GreenText%) else (set clr=%RedText%)
echo %BoldText%Average channel bandwidth estimated by curl:%DefaultText% %clr%%speed%KB/s%DefaultText%
echo.
set /A Counter=%Counter%+1
if not %Counter% GTR %ggcCounter% (goto TCPBANDLOOP)

::Testing TCP Connection Stability
echo.
echo %InverseText%Testing connection stability, %attempts% attempts%DefaultText%
echo.
set Counter=1
:TCPSTABLELOOP
set "ggcURL=https://rr%counter%%cluster%.googlevideo.com"
echo %BoldText%Testing%DefaultText% %ggcURL%...
set successes=0
SetLocal EnableDelayedExpansion
for /L %%i in (1,1,%attempts%) do (
curl -sko NUL -m 1 %ggcURL%
if !ERRORLEVEL!==0 (set /A successes=!successes!+1)
)
if !successes!==%attempts% (set clr=%GreenText%) else (set clr=%RedText%)
echo %BoldText%Succesful connections:%DefaultText% !clr!!successes! out of %attempts%%DefaultText%
echo.
EndLocal
set /A Counter=%Counter%+1
if not %Counter% GTR %ggcCounter% (goto TCPSTABLELOOP)

::Testing UDP Connection Stability
echo.
echo %InverseText%Testing QUIC connection stability, %attempts% attempts%DefaultText%
echo.
set Counter=1
:UDPSTABLELOOP
set "ggcURL=https://rr%counter%%cluster%.googlevideo.com"
echo %BoldText%Testing%DefaultText% %ggcURL%...
set successes=0
SetLocal EnableDelayedExpansion
for /L %%i in (1,1,%attempts%) do (
curl -sko NUL --http3-only -m 1 %ggcURL%
if !ERRORLEVEL!==0 (set /A successes=!successes!+1)
if !ERRORLEVEL!==95 (set /A successes=!successes!+1)
)
if !successes!==%attempts% (set clr=%GreenText%) else (set clr=%RedText%)
echo %BoldText%Succesful connections:%DefaultText% !clr!!successes! out of %attempts%%DefaultText%
echo.
EndLocal
set /A Counter=%Counter%+1
if not %Counter% GTR %ggcCounter% (goto UDPSTABLELOOP)

::Testing TCP Connection Stability (Parallel)
echo.
echo %InverseText%Testing connection stability, 10 attempts in parallel%DefaultText%
echo.
set Counter=1
:TCPSTABLEPARALLELLOOP
set "ggcURL=https://rr%counter%%cluster%.googlevideo.com"
echo %BoldText%Testing%DefaultText% %ggcURL%...
curl -skZm 3 --parallel-immediate --parallel-max 10 %ggcURL% %ggcURL% %ggcURL% %ggcURL% %ggcURL% %ggcURL% %ggcURL% %ggcURL% %ggcURL% %ggcURL% > NUL
if %ERRORLEVEL%==0 (echo %GreenText%Test passed%DefaultText%) else (echo %RedText%Test failed%DefaultText%)
echo.
set /A Counter=%Counter%+1
if not %Counter% GTR %ggcCounter% (goto TCPSTABLEPARALLELLOOP)

::Testing UDP Connection Stability (Parallel)
echo.
echo %InverseText%Testing QUIC connection stability, 10 attempts in parallel%DefaultText%
echo.
set Counter=1
:UDPSTABLEPARALLELLOOP
set "ggcURL=https://rr%counter%%cluster%.googlevideo.com"
echo %BoldText%Testing%DefaultText% %ggcURL%...
curl -skZm 3 --http3-only --parallel-immediate --parallel-max 10 %ggcURL% %ggcURL% %ggcURL% %ggcURL% %ggcURL% %ggcURL% %ggcURL% %ggcURL% %ggcURL% %ggcURL% > NUL
if %ERRORLEVEL%==0 (echo %GreenText%Test passed%DefaultText%) else (if %ERRORLEVEL%==95 (echo %GreenText%Test passed%DefaultText%) else (echo %RedText%Test failed%DefaultText%))
echo.
set /A Counter=%Counter%+1
if not %Counter% GTR %ggcCounter% (goto UDPSTABLEPARALLELLOOP)
echo.
echo %BoldText%Finished!%DefaultText%

:EOF

::Cleaning up...
set attempts=
set connect_to_url=
set volume_to_transfer=
set time_to_transfer=
set cluster=
set DefaultText=
set RedText=
set GreenText=
set BoldText=
set InverseText=
set customcluster=
set version=
set MajorVersion=
set MinorVersion=
set ggcCounter=
set ggcURL=
set Counter=
set speed=
set successes=

echo.
echo Press any button to exit...
pause>NUL
exit /b

:OUTDATED
echo.
echo %RedText%Curl outdated%DefaultText%
echo Obtain actual version at https://curl.se/
goto EOF