::by Ori - version 01.10.2024
@echo off
title GoodCheck
cls

SetLocal EnableDelayedExpansion

cd /d "%~dp0"


::==============================CONFIG================================
::General
set "checkMeList=checkme.txt"
set skipAutoISPsGCS=
set skipAutoTLS12BreakageTest=1

set "netConnTest=https://ya.ru"
set "tls12TestSite=https://tls-v1-2.badssl.com:1012"

set reportMappingURL[0]="https://redirector.gvt1.com/report_mapping?di=no" 
set reportMappingURL[1]="https://redirector.googlevideo.com/report_mapping?di=no"

::GoodbyeDPI
set "gdpiName=GoodbyeDPI"
set "gdpiExeName=goodbyedpi.exe"
set "gdpiExePathOverride="
set "gdpiServiceName=GoodbyeDPI"
set "gdpiStrategiesList=strategies_gdpi.txt"
set "gdpiFakeSNI=www.google.com"
set "gdpiFakeHex=1603030135010001310303424143facf5c983ac8ff20b819cfd634cbf5143c0005b2b8b142a6cd335012c220008969b6b387683dedb4114d466ca90be3212b2bde0c4f56261a9801"
set "gdpiAdditionalKeys=-q"

::Zapret
set "zapretName=Zapret"
set "zapretExeName=winws.exe"
set "zapretExePathOverride="
set "zapretServiceName=winws1"
set "zapretStrategiesList=strategies_zapret.txt"
set "zapretPayloadTLS=quic_initial_google_com.bin"
set "zapretPayloadQuic=tls_clienthello_www_google_com.bin"
set "zapretAdditionalKeys="

::CiaDPI
set "ciaName=ByeDPI"
set "ciaExeName=ciadpi.exe"
set "ciaExePathOverride="
set "ciaServiceName=ByeDPI"
set "ciaStrategiesList=strategies_cia.txt"
set "ciaAdditionalKeys="


::====================================================================
::Consts
::uzpkfa50vqlgb61wrmhc72xsnid83ytoje94-
::0123456789abcdefghijklmnopqrstuvwxyz-
set "lettersListA=u z p k f a 5 0 v q l g b 6 1 w r m h c 7 2 x s n i d 8 3 y t o j e 9 4 -"
set "lettersListB=0 1 2 3 4 5 6 7 8 9 a b c d e f g h i j k l m n o p q r s t u v w x y z -"

set "hash_gdpi_86_023rc32=9c3f16d5a0aff180f9d04ae6c0fe1f28"
set "hash_gdpi_64_023rc32=afa7f66231b9cec7237e738b622c0181"

set "hash_gdpi_86_023testbuild=a3131eabbf518ec6d8ed6dca8bf112e6"
set "hash_gdpi_64_023testbuild=4d060be292eb50783c0d8022d4bf246c"

set "hash_zapret_last=8c624e64742bc19447d52f61edec52db"

set "hash_cia_last=290bfd08896ebde8242a8573f6e678c7"


::====================================================================
::Initial checks
echo.

::Checking up if we have admin rights
net session >NUL 2>&1
if not %ERRORLEVEL%==0 (
	echo ERROR: This script requires elevated privilegies
	echo.
	echo You need to right click on "%~n0%~x0" and choose "Run as administrator"
	goto EOF
)

::Checking up that checklist do exist
if not exist !checkmeList! (
	echo WARNING: Can't find "!checkmeList!", continuing anyway...
	echo.
)

::Checking up that curl do exist
curl -V >NUL
if not !ERRORLEVEL!==0 (
	echo ERROR: Can't find Curl
	echo.
	echo Download it at https://curl.se/ and put the content of /bin/ folder next to this script
	goto EOF
)

::Checking up network connectivity
::Apparently ICMP is blocked for some people, so we use curl here
rem ping -n 1 -w 2000 "!netConnTest!">NUL
curl -so NUL "!netConnTest!"
if not !ERRORLEVEL!==0 (
	echo ERROR: No network connection
	goto EOF
)


::====================================================================
::Looking for executables and strategies

::...for GDPI
set "subFolder=x86\"
if "%PROCESSOR_ARCHITECTURE%"=="AMD64" (set "subFolder=x86_64\")
if defined PROCESSOR_ARCHITEW6432 (set "subFolder=x86_64\")

if defined gdpiExePathOverride (
	call :LookForExe "!gdpiExeName!" "!gdpiExePathOverride!" "!gdpiName!" gdpiExeFullpath
	if not defined gdpiExeFullpath (
		call :LookForExe "!subFolder!!gdpiExeName!" "!gdpiExePathOverride!" "!gdpiName!" gdpiExeFullpath
	)
)
if not defined gdpiExeFullpath (
	call :LookForExe "!gdpiExeName!" "%~dp0" "!gdpiName!" gdpiExeFullpath
)
if not defined gdpiExeFullpath (
	call :LookForExe "!gdpiExeName!" "%~dp0!subFolder!" "!gdpiName!" gdpiExeFullpath
)
if not defined gdpiExeFullpath (
	echo Can't find !gdpiName! anywhere :(
) else (
	::...Checking if it's outdated
	call :CalculateHash !gdpiExeFullpath! hash
	set confirmed=
	if !hash!==!hash_gdpi_64_023testbuild! (
		echo You're using 64-bit test build version with --fake-with-sni support. Very nice.
		set confirmed=1
	)
	if !hash!==!hash_gdpi_86_023testbuild! (
		echo You're using 32-bit test build version with --fake-with-sni support. Very nice.
		set confirmed=1
	)
	if !hash!==!hash_gdpi_64_023rc32! (
		echo You're using 64-bit 0.2.3-rc3-2 version. It doesn't have --fake-with-sni support, but supports --fake-from-hex
		set confirmed=1
	)
	if !hash!==!hash_gdpi_86_023rc32! (
		echo You're using 32-bit 0.2.3-rc3-2 version. It doesn't have --fake-with-sni support, but supports --fake-from-hex
		set confirmed=1
	)
	if not defined confirmed (
		echo You're using either outdated or unknown version of !gdpiName! - it can cause problems
	)
)
echo.

::...for Zapret
if defined zapretExePathOverride (
	call :LookForExe "!zapretExeName!" "!zapretExePathOverride!" "!zapretName!" zapretExeFullpath
)
if not defined zapretExeFullpath (
	call :LookForExe "!zapretExeName!" "%~dp0" "!zapretName!" zapretExeFullpath
)
if not defined zapretExeFullpath (
	echo Can't find !zapretName! anywhere :(
) else (
	::...Checking if it's outdated
	call :CalculateHash !zapretExeFullpath! hash
	set confirmed=
	if !hash!==!hash_zapret_last! (
		echo You're using last version of !zapretName!
		set confirmed=1
	)
	if not defined confirmed (
		echo You're using either outdated or unknown version of !zapretName! - it can cause problems
	)
)
echo.

::...for ByeDPI
if defined ciaExePathOverride (
	call :LookForExe "!ciaExeName!" "!ciaExePathOverride!" "!ciaName!" ciaExeFullpath
)
if not defined ciaExeFullpath (
	call :LookForExe "!ciaExeName!" "%~dp0" "!ciaName!" ciaExeFullpath
)
if not defined ciaExeFullpath (
	echo Can't find !ciaName! anywhere :(
) else (
	::...Checking if it's outdated
	call :CalculateHash !ciaExeFullpath! hash
	set confirmed=
	if !hash!==!hash_cia_last! (
		echo You're using last version of !ciaName!
		set confirmed=1
	)
	if not defined confirmed (
		echo You're using either outdated or unknown version of !ciaName! - it can cause problems
	)
)
echo.

::Checking up that strategies list do exist
if defined gdpiExeFullpath (
	call :LookForStrategiesList "!gdpiStrategiesList!" "!gdpiName!" gdpiStrategiesList
) else (
	set gdpiStrategiesList=
)
if defined zapretExeFullpath (
	call :LookForStrategiesList "!zapretStrategiesList!" "!zapretName!" zapretStrategiesList
) else (
	set zapretStrategiesList=
)
if defined ciaExeFullpath (
	call :LookForStrategiesList "!ciaStrategiesList!" "!ciaName!" ciaStrategiesList
) else (
	set ciaStrategiesList=
)

::Checking up that at least one executable with corresponding strategies list is found
if not defined gdpiStrategiesList if not defined zapretStrategiesList if not defined ciaStrategiesList (
	echo.
	echo ERROR: Nothing to do.
	echo Make sure that executables and their strategies are in place.
	goto EOF
)

echo.
echo ----------------
echo.

::====================================================================
::User choosing a test provider here

echo Test is ready.
echo.
echo !gdpiName!, !zapretName! and !ciaName! will be closed
echo Their services will be stopped and removed
echo.
echo.

::Lifehack for elements to be in order. Don't press shift+ABC during this choice - it will break stuff
if defined gdpiStrategiesList (
	echo Press [1] - test with !gdpiName!
	set choiceTest=!choiceTest!1
) else (
	echo -
	set choiceTest=!choiceTest!A
)
if defined zapretStrategiesList (
	echo Press [2] - test with !zapretName!
	set choiceTest=!choiceTest!2
) else (
	echo -
	set choiceTest=!choiceTest!B
)
if defined ciaStrategiesList (
	echo Press [3] - test with !ciaName!
	set choiceTest=!choiceTest!3
) else (
	echo -
	set choiceTest=!choiceTest!C
)
set choiceTest=!choiceTest!0
echo Press [0] - cancel and exit

choice /C !choiceTest! /CS >NUL
set userTestChoice=!ERRORLEVEL!

if !userTestChoice!==4 (goto EOF)

if !userTestChoice!==1 (
	set "strategiesList=!gdpiStrategiesList!"
	set "exeName=!gdpiExeName!"
	set "serviceName=!gdpiServiceName!"
	set "exeFullpath=!gdpiExeFullpath!"
	set "programName=!gdpiName!"
)

if !userTestChoice!==2 (
	set "strategiesList=!zapretStrategiesList!"
	set "exeName=!zapretExeName!"
	set "serviceName=!zapretServiceName!"
	set "exeFullpath=!zapretExeFullpath!"
	set "programName=!zapretName!"
)

if !userTestChoice!==3 (
	set "strategiesList=!ciaStrategiesList!"
	set "exeName=!ciaExeName!"
	set "serviceName=!ciaServiceName!"
	set "exeFullpath=!ciaExeFullpath!"
	set "programName=!ciaName!"
)

call :PurgeProgram "!gdpiExeName!"
call :PurgeProgram "!zapretExeName!"
call :PurgeProgram "!ciaExeName!"

call :PurgeService "!gdpiServiceName!"
call :PurgeService "!zapretServiceName!"
call :PurgeService "!ciaServiceName!"

call :PurgeWinDivert


::====================================================================
::Creating log
set "_time=%time:~0,-3%"
set "_time=!_time: =0!"
set "_time2=!_time::=-!"
set "_date=%date:.=-%"
set "_date=!_date:/=-!"
set "_date=!_date: =_!"
set logFileName="log_GoodCheck_!programName: =_!_!_date!_!_time2!.txt"

echo GoodCheck Log for !programName! - !_date! - !_time!>!logFileName!

if not exist !logFileName! (
echo.
echo WARNING: Problem encountered during logfile creation, attempting workaround
	set logFileName="logfile%random%.txt"
	echo GoodCheck Log for !programName! - !_date! - !_time!>!logFileName!
	if not exist !logFileName! (
		set logFileName=
		echo ERROR: Can't create logfile. Press any button to continue
		pause>NUL
	)
)

call :WriteToLog 
call :WriteToLog ---------------------
call :WriteToLog 
for /F "tokens=*" %%i in ('curl -V') do (call :WriteToLog %%i)
call :WriteToConsoleAndToLog 
call :WriteToConsoleAndToLog ---------------------
call :WriteToConsoleAndToLog 


::====================================================================
if defined skipAutoISPsGCS (goto SKIPAUTOGCS)

::Extracting our GGC cluster codename
call :ExtractClusterCodename clusterCodename
if defined clusterCodename (
	call :WriteToConsoleAndToLog Your cluster codename: !clusterCodename!
) else (
	echo ERROR: Can't extract cluster codename
	echo Make sure !reportMappingURL[0]! is accessible
	echo.
	echo Or set "skipAutoISPsGCS=1" in the script to auto-skip this part
	goto EOF
)

::Turning letter lists into letter arrays
set lettersArrayLen=-1
for %%i in (!lettersListA!) do (
	set /A lettersArrayLen+=1
	set lettersArrayA[!lettersArrayLen!]=%%i
)
set lettersArrayLen=-1
for %%i in (!lettersListB!) do (
	set /A lettersArrayLen+=1
	set lettersArrayB[!lettersArrayLen!]=%%i
)

::Converting our cluster codename into a proper web address
for /L %%i in (0,1,99) do (
	set "letter=!clusterCodename:~%%i,1!"
	if not defined letter (goto BREAKCONVCODENAME)
	
	for /L %%j in (0,1,!lettersArrayLen!) do (
		if !letter!==!lettersArrayA[%%j]! (set clusterName=!clusterName!!lettersArrayB[%%j]!)
	)
)
:BREAKCONVCODENAME

set "autoGCS=https://rr1---sn-!clusterName!.googlevideo.com"

call :WriteToConsoleAndToLog Your GGC server web address: !autoGCS!
call :WriteToConsoleAndToLog
call :WriteToConsoleAndToLog -------------------------------
call :WriteToConsoleAndToLog

:SKIPAUTOGCS


::====================================================================
::Converting strategies list into an array
set strategiesNum=-1
for /F "tokens=* eol=/" %%i in (!strategiesList!) do (
	set /A strategiesNum+=1
	
	call :FormatStrategy "%%i" !userTestChoice! strategy
	set "strategiesArray[!strategiesNum!]=!strategy!"
)


::====================================================================
::Forming URL line for curl threaded requests
set curlThreadsNum=0
set curlURL=

if not defined skipAutoTLS12BreakageTest (
	set /A curlThreadsNum+=1
	set curlURL=!curlURL! -o NUL "!tls12TestSite!"
	call :WriteToConsoleAndToLog Site to test: !tls12TestSite! ^(TLS 1.2 Test site^)
)

if not defined skipAutoISPsGCS (
	set /A curlThreadsNum+=1
	set curlURL=!curlURL! -o NUL "!autoGCS!"
	call :WriteToConsoleAndToLog Site to test: !autoGCS! ^(Your ISP GGC Server^)
)

if exist !checkmeList! (
	for /F "tokens=* eol=/" %%i in (!checkMeList!) do (
		set /A curlThreadsNum+=1
		call :CleanURL "%%i" url
		call :WriteToConsoleAndToLog Site to test: !url!
		set curlURL=!curlURL! -o NUL "!url!"
	)
)

::Estimating curl timeout: 2 sec for less than 50 threads, then +1 sec for every additional 50 threads
set curlParallelRequestTimeout=2
for /L %%i in (50,50,1000) do (
	if !curlThreadsNum! GTR %%i (
		set /A curlParallelRequestTimeout+=1
	) else (
		goto BREAKTIMEOUTESTIM
	)
)
:BREAKTIMEOUTESTIM

call :WriteToConsoleAndToLog
if  !curlThreadsNum!==0 (
	call :WriteToConsoleAndToLog ERROR: Nothing to test
	goto EOF
)
call :WriteToConsoleAndToLog -------------------------------
call :WriteToConsoleAndToLog


::====================================================================
::Main testing loop
for /L %%i in (0,1,!strategiesNum!) do (

	title GoodCheck - Testing in progress: %%i out of !strategiesNum!
	
	call :WriteToConsoleAndToLog Testing ^(%%i/!strategiesNum!^): !strategiesArray[%%i]!
	
	start "!programName! - Launched through GoodCheck - Strategy %%i out of !strategiesNum!" /min "!exeFullpath!" !strategiesArray[%%i]!

	set "result="
	::Making request to see if servers are reachable. Timeout is neccessary to give program some time to load. Default timeout command is unreleable, using lifehack
	rem timeout /T 2 >NUL
	choice /C Q /D Q /CS /T 1 >NUL
	for /F "tokens=*" %%j in ('curl -sm !curlParallelRequestTimeout! -w "%%{url}$%%{exitcode} " -Z --parallel-immediate --parallel-max !curlThreadsNum!!curlURL!') do (
		set "result=!result!%%j"
	)
	
	call :PurgeProgram "!exeName!"
	rem call :PurgeService "!serviceName!"
	rem call :PurgeWinDivert
	
	::Parsing result
	set successes=0
	set tls12BreakageMessage=
	
	for %%j in (!result!) do (
		for /F "tokens=1,2 delims=$" %%p in ("%%j") do (
			if %%q==0 (
				set /A successes+=1
				call :WriteToConsoleAndToLog WORKING		%%p
			) else (
				call :WriteToConsoleAndToLog NOT WORKING	%%p
			)
			if "%%p"=="!tls12TestSite!" (
				if not %%q==0 (set "tls12BreakageMessage=   (TLS 1.2 Possible Breakage)")
			)
		)
	)
	
	call :WriteToConsoleAndToLog  Successes: !successes!/!curlThreadsNum!!tls12BreakageMessage!
	call :WriteToConsoleAndToLog
	
	::Writing to a variable for future use
	set "resultsArray[%%i]=!successes!/!strategiesArray[%%i]!!tls12BreakageMessage!"
)

title GoodCheck - Completed

call :WriteToConsoleAndToLog -------------------------------
call :WriteToConsoleAndToLog


::====================================================================
::Showcasing results and writing it to a file
for /L %%i in (0,1,!curlThreadsNum!) do (
	call :WriteToConsoleAndToLog Strategies with %%i out of !curlThreadsNum! successes:
	for /L %%j in (0,1,!strategiesNum!) do (
		for /F "tokens=1,2 delims=/" %%k in ("!resultsArray[%%j]!") do (
			if "%%k"=="%%i" (
				call :WriteToConsoleAndToLog %%l
			)
		)
	)
	call :WriteToConsoleAndToLog
)
echo -------------------------------
echo.
echo Saved to !logFileName!

goto EOF


::====================================================================

:PurgeProgram
SetLocal EnableDelayedExpansion
set "taskName=%~1"
taskkill /T /F /IM !taskName! >NUL 2>&1
EndLocal
exit /b

:PurgeService
SetLocal EnableDelayedExpansion
set "serviceName=%~1"
net stop !serviceName! >NUL 2>&1
sc delete !serviceName! >NUL 2>&1
EndLocal
exit /b

:PurgeWinDivert
net stop "WinDivert" >NUL 2>&1
sc delete "WinDivert" >NUL 2>&1
net stop "WinDivert14" >NUL 2>&1
sc delete "WinDivert14" >NUL 2>&1
exit /b

:WriteToConsoleAndToLog
SetLocal EnableDelayedExpansion
set "message=%*"
if '!message!'=='' (
	echo.
	if defined logFileName (
		echo.>>!logFileName!
	)
) else (
	echo !message!
	if defined logFileName (
		echo !message!>>!logFileName!
	)
)
EndLocal
exit /b

:WriteToLog
SetLocal EnableDelayedExpansion
set "message=%*"
if '!message!'=='' (
	if defined logFileName (
		echo.>>!logFileName!
	)
) else (
	if defined logFileName (
		echo !message!>>!logFileName!
	)
)
EndLocal
exit /b

:ExtractClusterCodename
SetLocal EnableDelayedExpansion
set result=
for /L %%i in (0,1,10) do (
	if not defined result (
		if not "!reportMappingURL[%%i]!"=="" (
			for /F "tokens=3 delims= " %%j in ('curl -sm 2 !reportMappingURL[%%i]!') do (
				set "result=%%j"
			)
		)
	)
)
EndLocal && (set "%~1=%result%")
exit /b

:LookForExe
SetLocal EnableDelayedExpansion
set "exe=%~1"
set "path=%~2"
set "name=%~3"
set "fullpath=!path!!exe!"
if exist "!fullpath!" (
	echo !name! is found at !fullpath!
) else (
	REM echo !name! NOT found at !fullpath!
	set "fullpath=!path!\!exe!"
	if exist "!fullpath!" (
		echo !name! is found at !fullpath!
	) else (
		REM echo !name! NOT found at !fullpath!
		set fullpath=
	)
)
EndLocal && (set "%~4=%fullpath%")
exit /b

:LookForStrategiesList
SetLocal EnableDelayedExpansion
set "list=%~1"
set "name=%~2"
if not exist !list! (
	echo WARNING: Can't find strategies list for !name!. Make sure that !list! is in the same folder as this script.
	set "list="
) else (
	echo Strategies list for !name! is found.
)
EndLocal && (set "%~3=%list%")
exit /b

:CleanURL
SetLocal EnableDelayedExpansion
set "url=%~1"
set "url=!url:https://=!"
set "url=!url:http://=!"
for /F "tokens=1 delims=/" %%i in ("!url!") do (
	set "url=https://%%i"
)
EndLocal && (set "%~2=%url%")
exit /b

:FormatStrategy
SetLocal EnableDelayedExpansion
set "strategy=%~1"
set mode=%~2
::mode for GDPI
if !mode!==1 (
	set "strategy=!strategy:FAKESNI=%gdpiFakeSNI%!"
	set "strategy=!strategy:FAKEHEX=%gdpiFakeHex%!"
	set "strategy=!strategy! !gdpiAdditionalKeys!"
)
::mode for Zapret
if !mode!==2 (
	set "strategy=!strategy:PAYLOADTLS=%zapretPayloadTLS%!"
	set "strategy=!strategy:PAYLOADQUIC=%zapretPayloadQuic%!"
	set "strategy=!strategy! !zapretAdditionalKeys!"
)
::mode for ByeDPI
if !mode!==3 (
	set "strategy=!strategy! !ciaAdditionalKeys!"
)
EndLocal && (set "%~3=%strategy%")
exit /b

:CalculateHash
SetLocal EnableDelayedExpansion
set "file=%~1"
set count=0
set hash=0
for /F %%i in ('certutil -hashfile !file! MD5') do (
	set /A count+=1
	if !count!==2 (set hash=%%i)
)
EndLocal && (set "%~2=%hash%")
exit /b

::====================================================================

:EOF
EndLocal

echo.
echo.
echo Press any button to exit...
pause>NUL

title %comspec%
exit /b