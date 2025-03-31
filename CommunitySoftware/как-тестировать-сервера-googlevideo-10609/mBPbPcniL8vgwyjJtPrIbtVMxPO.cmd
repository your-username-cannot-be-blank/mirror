::by Ori
chcp 1251
@echo off
cls

::==========Setting variables==========
::User-defined
set attempts=10
set "connect_to_url=speedtest.selectel.ru"
set volume_to_transfer=10
set time_to_transfer=5
set Timeout=2
set LaxTimeout=3
::set "proxy=socks5h://127.0.0.1:9150"

::Don't change these ones
set customcluster=%*
set cluster=0
set "DefaultText=[0m"
set "RedText=[91m"
set "GreenText=[92m"
set "BoldText=[1m"
set "InverseText=[7m"
if defined proxy (set "proxy= --proxy %proxy%")

::==========Checking Curl version==========
for /F "tokens=1,2 delims= " %%i in ('curl -V') do (if "%%i"=="curl" set version=%%j)
for /F "tokens=1,2 delims=." %%i in ("%version%") do (set MajorVersion=%%i && set MinorVersion=%%j)
if %MajorVersion% GEQ 8 (if %MinorVersion% GEQ 10 (goto CLUSTERSEARCH))
echo.
echo %RedText%Curl outdated%DefaultText%
echo Obtain actual version at https://curl.se/
goto EOF

::==========Cluster codename search==========
:CLUSTERSEARCH
echo.
echo %InverseText%Looking for cluster codename%DefaultText%
echo.
if not defined customcluster (goto USERINPUTCLUSTER)
:PARSECUSTOMCLUSTER
::Parsing custom cluster codename
for /F "tokens=1 delims=." %%i in ("%customcluster%") do (set "customcluster=%%i")
for /F "tokens=1* delims=-" %%i in ("%customcluster%") do (set "customcluster=%%j")
set "cluster=%customcluster%"
echo %BoldText%Cluster codename:%DefaultText% %cluster:sn-=%
set "cluster=---%cluster%"
goto PINGING

:USERINPUTCLUSTER
::Custom input by user
set /P customcluster="Input googlevideo URL or press ENTER for auto: "
echo.
if defined customcluster (goto PARSECUSTOMCLUSTER)

::Auto cluster
for /F "tokens=3 delims= " %%i in ('curl%proxy% -sm %LaxTimeout% "https://redirector.googlevideo.com/report_mapping?di=no"') do (set cluster=%%i)
if %cluster%==0 ((echo %RedText%Failure! Cannot establish connection to googlevideo.com to find a cluster codename%DefaultText%) && (goto EOF))

::===========Coverting a cluster codename into a proper (lmao) cluster codename===========
SetLocal EnableDelayedExpansion

::Setting variables
::uzpkfa50vqlgb61wrmhc72xsnid83ytoje94-
::0123456789abcdefghijklmnopqrstuvwxyz-
set "ListA=u z p k f a 5 0 v q l g b 6 1 w r m h c 7 2 x s n i d 8 3 y t o j e 9 4 -"
set "ListB=0 1 2 3 4 5 6 7 8 9 a b c d e f g h i j k l m n o p q r s t u v w x y z -"

::Turning lists into arrays
set num=0
for %%i in (%ListA%) do (
set ArrayA[!num!]=%%i
set /A num+=1
)
set num=0
for %%i in (%ListB%) do (
set ArrayB[!num!]=%%i
set /A num+=1
)

::Turning cluster name into array
for /L %%i in (0,1,30) do (
if not "!cluster:~%%i,1!"=="" (set ArrayCluster[%%i]=!cluster:~%%i,1!)
)

::Checking letters against ArrayA and using corresponding values from ArrayB to form a proper cluster name
set cluster=
for /L %%i in (0,1,30) do (
for /L %%j in (0,1,36) do (
if !ArrayCluster[%%i]!==!ArrayA[%%j]! (set cluster=!cluster!!ArrayB[%%j]!)
)
)

EndLocal && (set cluster=%cluster%)

echo %BoldText%Cluster codename:%DefaultText% %cluster%
set "cluster=---sn-%cluster%"
::========================================================================================

::==========Pinging servers to count them==========
:PINGING
echo.
echo.
echo %InverseText%Pinging servers, %Timeout% seconds timeout%DefaultText%
echo.
set ggcCounter=1
set /A PingTimeout=%Timeout%*1000
:PINGINGLOOP
set ggcURL=rr%ggcCounter%%cluster%.googlevideo.com
echo %BoldText%Pinging%DefaultText% %ggcURL%...
ping -n 1 -w %PingTimeout% %ggcURL% >NUL
if %ERRORLEVEL%==0 ((echo %GreenText%Success%DefaultText%) && (set /A ggcCounter+=1) && (echo.) && (goto PINGINGLOOP))
echo %RedText%Failure%DefaultText%
set /A ggcCounter-=1
if %ggcCounter%==0 (
echo.
echo %RedText%Can't find a single working server%DefaultText%
goto EOF
)

::==========Testing TCP Connection==========
echo.
echo.
echo %InverseText%Testing connectivity, %Timeout% seconds timeout%DefaultText%
echo.
set Counter=1
:TCPCONNLOOP
set "ggcURL=https://rr%counter%%cluster%.googlevideo.com"
echo %BoldText%Testing%DefaultText% %ggcURL%...
curl%proxy% -sko NUL -m %Timeout% -w "DNS_T: %%{time_namelookup} s | Connection_T: %%{time_connect} s | Handshake_T: %%{time_appconnect} s | Total_T: %%{time_total} s | Header: %%{size_header} bytes\n" %ggcURL%
if %ERRORLEVEL%==0 (echo %GreenText%Test passed%DefaultText%) else (echo %RedText%Test failed%DefaultText%)
echo.
set /A Counter+=1
if not %Counter% GTR %ggcCounter% (goto TCPCONNLOOP)

::==========Testing UDP Connection==========
echo.
echo %InverseText%Testing QUIC connectivity, %Timeout% seconds timeout%DefaultText%
echo.
set Counter=1
:UDPCONNLOOP
set "ggcURL=https://rr%counter%%cluster%.googlevideo.com"
echo %BoldText%Testing%DefaultText% %ggcURL%...
curl%proxy% -sko NUL -m %Timeout% --http3-only -w "DNS_T: %%{time_namelookup} s | Connection_T: %%{time_connect} s | Handshake_T: %%{time_appconnect} s | Total_T: %%{time_total} s | Header: %%{size_header} bytes\n" %ggcURL%
if %ERRORLEVEL%==0 (echo %GreenText%Test passed%DefaultText%) else (if %ERRORLEVEL%==95 (echo %GreenText%Test passed%DefaultText%) else (echo %RedText%Test failed%DefaultText%))
echo.
set /A Counter+=1
if not %Counter% GTR %ggcCounter% (goto UDPCONNLOOP)

::==========Testing TCP bandwidth==========
echo.
echo %InverseText%Testing channel bandwidth using %connect_to_url%, %volume_to_transfer%MB transfer, %time_to_transfer% seconds timeout%DefaultText%
echo.
set "ggcURL=https://rr1%cluster%.googlevideo.com"
echo %BoldText%Testing...%DefaultText%
::set Counter=1
:::TCPBANDLOOP
::set "ggcURL=https://rr%counter%%cluster%.googlevideo.com"
::echo %BoldText%Testing%DefaultText% %ggcURL%...
set speed=0
for /F %%i in ('curl%proxy% -sko NUL -m %time_to_transfer% --connect-to ::%connect_to_url% %ggcURL%/%volume_to_transfer%MB -w "%%{speed_download}"') do set speed=%%i
set /A speed=%speed%*10/1048576
if %speed% GTR 10 (set clr=%GreenText%) else (set clr=%RedText%)
if %speed%==0 (echo %clr%Failed to receive data%DefaultText%) else (echo %BoldText%Average channel bandwidth estimated by curl:%DefaultText% %clr%%speed:~0,-1%.%speed:~-1% MB/s%DefaultText%)
::set /A Counter+=1
::if not %Counter% GTR %ggcCounter% (goto TCPBANDLOOP)

::==========Testing TCP Connection Stability==========
echo.
echo.
echo %InverseText%Testing connection stability, %attempts% attempts, %Timeout% seconds timeout%DefaultText%
echo.
set Counter=1
:TCPSTABLELOOP
set "ggcURL=https://rr%counter%%cluster%.googlevideo.com"
echo %BoldText%Testing%DefaultText% %ggcURL%...
set successes=0
set timeTotal=0
SetLocal EnableDelayedExpansion
for /L %%i in (1,1,%attempts%) do (
for /F "tokens=1,2" %%j in ('curl%proxy% -sko NUL -m %Timeout% -w "%%{time_total} %%{response_code}" %ggcURL%') do (
if not %%k==000 (
set /A successes+=1
set "time=%%j"
set "time=100!time:.=!"
set "time=!time:~0,-2!"
set /A timeTotal=!timeTotal!+!time!
)
)
)
if !successes!==%attempts% (set clr=%GreenText%) else (set clr=%RedText%)
if !successes!==0 (
echo %BoldText%Succesful connections:%DefaultText% !clr!!successes! out of %attempts%%DefaultText%
) else (
set /A timeTotal=!timeTotal!/!successes!
set timeTotal=!timeTotal:~3!
echo %BoldText%Succesful connections:%DefaultText% !clr!!successes! out of %attempts%%DefaultText% ^| %BoldText%Average time on success:%DefaultText% !timeTotal:~0,1!.!timeTotal:~1! s
)
echo.
EndLocal
set /A Counter+=1
if not %Counter% GTR %ggcCounter% (goto TCPSTABLELOOP)

::==========Testing UDP Connection Stability==========
echo.
echo %InverseText%Testing QUIC connection stability, %attempts% attempts, %Timeout% seconds timeout%DefaultText%
echo.
set Counter=1
:UDPSTABLELOOP
set "ggcURL=https://rr%counter%%cluster%.googlevideo.com"
echo %BoldText%Testing%DefaultText% %ggcURL%...
set successes=0
set timeTotal=0
SetLocal EnableDelayedExpansion
for /L %%i in (1,1,%attempts%) do (
for /F "tokens=1,2" %%j in ('curl%proxy% -sko NUL --http3-only -m %Timeout% -w "%%{time_total} %%{response_code}" %ggcURL%') do (
if not %%k==000 (
set /A successes+=1
set "time=%%j"
set "time=100!time:.=!"
set "time=!time:~0,-2!"
set /A timeTotal=!timeTotal!+!time!
)
)
)
if !successes!==%attempts% (set clr=%GreenText%) else (set clr=%RedText%)
if !successes!==0 (
echo %BoldText%Succesful connections:%DefaultText% !clr!!successes! out of %attempts%%DefaultText%
) else (
set /A timeTotal=!timeTotal!/!successes!
set timeTotal=!timeTotal:~3!
echo %BoldText%Succesful connections:%DefaultText% !clr!!successes! out of %attempts%%DefaultText% ^| %BoldText%Average time on success:%DefaultText% !timeTotal:~0,1!.!timeTotal:~1! s
)
echo.
EndLocal
set /A Counter+=1
if not %Counter% GTR %ggcCounter% (goto UDPSTABLELOOP)

::==========Testing TCP Connection Stability (Parallel)==========
echo.
echo %InverseText%Testing connection stability, 10 attempts in parallel, %LaxTimeout% seconds timeout%DefaultText%
echo.
set Counter=1
:TCPSTABLEPARALLELLOOP
set "ggcURL=https://rr%counter%%cluster%.googlevideo.com"
echo %BoldText%Testing%DefaultText% %ggcURL%...
curl%proxy% -skZm %LaxTimeout% --parallel-immediate --parallel-max 10 %ggcURL% %ggcURL% %ggcURL% %ggcURL% %ggcURL% %ggcURL% %ggcURL% %ggcURL% %ggcURL% %ggcURL% > NUL
if %ERRORLEVEL%==0 (echo %GreenText%Test passed%DefaultText%) else (echo %RedText%Test failed%DefaultText%)
echo.
set /A Counter+=1
if not %Counter% GTR %ggcCounter% (goto TCPSTABLEPARALLELLOOP)

::==========Testing UDP Connection Stability (Parallel)==========
echo.
echo %InverseText%Testing QUIC connection stability, 10 attempts in parallel, %LaxTimeout% seconds timeout%DefaultText%
echo.
set Counter=1
:UDPSTABLEPARALLELLOOP
set "ggcURL=https://rr%counter%%cluster%.googlevideo.com"
echo %BoldText%Testing%DefaultText% %ggcURL%...
curl%proxy% -skZm %LaxTimeout% --http3-only --parallel-immediate --parallel-max 10 %ggcURL% %ggcURL% %ggcURL% %ggcURL% %ggcURL% %ggcURL% %ggcURL% %ggcURL% %ggcURL% %ggcURL% > NUL
if %ERRORLEVEL%==0 (echo %GreenText%Test passed%DefaultText%) else (if %ERRORLEVEL%==95 (echo %GreenText%Test passed%DefaultText%) else (echo %RedText%Test failed%DefaultText%))
echo.
set /A Counter+=1
if not %Counter% GTR %ggcCounter% (goto UDPSTABLEPARALLELLOOP)
echo.
echo %BoldText%Finished!%DefaultText%

::==========The End Bro==========
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
set clr=
set proxy=
set Timeout=
set LaxTimeout=
set PingTimeout=
set timeTotal=

echo.
echo Press any button to exit...
pause>NUL
exit /b