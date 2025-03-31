::by Ori
::todo translation
@echo off
chcp 1251
title GoodCheck
cls

SetLocal EnableDelayedExpansion


::==============================CONFIG================================
::General
set skipAutoISPsGCS=false
set skipAutoTLS12BreakageTest=true
set outputMostSuccessfulStrategiesSeparately=false

::Additional options
set "curlExtraKeys="
set "curlMinTimeout=2"

set "dohEnabled=true"
set "curlDoH[0]=https://one.one.one.one/dns-query"
set "curlDoH[1]=https://1.1.1.1/dns-query"
set "curlDoH[2]=https://1.1.1.2/dns-query"
set "curlDoH[3]=https://dns.google/dns-query"
set "curlDoH[4]=https://mozilla.cloudflare-dns.com/dns-query"
set "curlDoH[5]=https://dns10.quad9.net/dns-query"
set "curlDoH[6]=https://dns.controld.com/comss"
set "curlDoH[7]=https://freedns.controld.com/p0"
set "curlDoH[8]=https://dns.comss.one/dns-query"

set "customCommonResolverEnabled=false"
set "customResolverIPv=4"
set "resolver[0]=1.1.1.1"
set "resolver[1]=8.8.8.8"
set "resolver[2]=9.9.9.9"
set "resolver[3]=1.0.0.1"
set "resolver[4]=8.8.4.4"

set "curlAntiFreeze=true"
set "curlAntiFreezeTempFile=CurlOutput.tmp"

::Folders and files
set "mostSuccessfulStrategiesFile=MostSuccessfulStrategies.txt"
set "checkListFolder=CheckLists"
set "strategiesFolder=Strategies"
set "curlFolder=Curl"
set "payloadsFolder=Payloads"
set "logsFolder=Logs"

::Strategy-related
set "fakeSNI=www.google.com"
set "fakeHexRaw=1603030135010001310303424143facf5c983ac8ff20b819cfd634cbf5143c0005b2b8b142a6cd335012c220008969b6b387683dedb4114d466ca90be3212b2bde0c4f56261a9801"
set "fakeHexBytes="
set "payloadTLS=tls_earth_google_com.bin"
set "payloadQuic=quic_ietf_www_google_com.bin"

::Web addresses for some functions
set "netConnTestURL=https://ya.ru"
set "tls12TestURL=https://tls-v1-2.badssl.com:1012"

set "reportMappingURL[0]=https://redirector.gvt1.com/report_mapping?di=no" 
set "reportMappingURL[1]=https://redirector.googlevideo.com/report_mapping?di=no"

::Testing programs
:: GoodbyeDPI
set "gdpiName=GoodbyeDPI"
set "gdpiExeName=goodbyedpi.exe"
set "gdpiFolderOverride="
set "gdpiServiceName=GoodbyeDPI"

:: Zapret
set "zapretName=Zapret"
set "zapretExeName=winws.exe"
set "zapretFolderOverride="
set "zapretServiceName=winws1"

:: ByeDPI
set "ciaName=ByeDPI"
set "ciaExeName=ciadpi.exe"
set "ciaFolderOverride="
set "ciaServiceName=ByeDPI"


::====================================================================
::Consts
set "version=v1.3.03"

set "goodCheckFolder=%~dp0"

(set nl=^
%emptyline%
)

::uzpkfa50vqlgb61wrmhc72xsnid83ytoje94-
::0123456789abcdefghijklmnopqrstuvwxyz-
set "lettersListA=u z p k f a 5 0 v q l g b 6 1 w r m h c 7 2 x s n i d 8 3 y t o j e 9 4 -"
set "lettersListB=0 1 2 3 4 5 6 7 8 9 a b c d e f g h i j k l m n o p q r s t u v w x y z -"

set "choiceList=1 2 3 4 5 6 7 8 9 a b c d e f g h i j k l m n o p q r s t u v w x y z"

::Hashes for programs
:: GDPI
::last official
set "hash_gdpi_86_023rc32=9c3f16d5a0aff180f9d04ae6c0fe1f28"
set "hash_gdpi_64_023rc32=afa7f66231b9cec7237e738b622c0181"

::test builds
set "hash_gdpi_86_023testbuild=a3131eabbf518ec6d8ed6dca8bf112e6"
set "hash_gdpi_64_023testbuild=4d060be292eb50783c0d8022d4bf246c"
set "hash_gdpi_64_testbuild_by_Decavoid=c25b01de6d5471f3b7337122049827f6"

:: Zapret last
set "hash_zapret_last=8c624e64742bc19447d52f61edec52db"

:: ByeDPI last
set "hash_cia_last=290bfd08896ebde8242a8573f6e678c7"


::====================================================================
::Turning letter lists into letter arrays for later
set choiceArrayLen=-1
for %%i in (!choiceList!) do (
	set /A choiceArrayLen+=1
	set choiceArray[!choiceArrayLen!]=%%i
)
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


::====================================================================
title GoodCheck !version!

::0 for no errors, 1 for minor errors, 2 for a critical error
set endedWithErrors=0

::Creating log
set "_time=%time:~0,-3%"
set "_time=!_time: =0!"
set "_time2=!_time::=-!"
set "_date=%date:.=-%"
set "_date=!_date:/=-!"
set "_date=!_date: =_!"

echo.
echo Creating log file...

set "logsFolder=!goodCheckFolder!!logsFolder!"
if not exist !logsFolder! (
	echo WARNING: Logs folder doesn't exist, creating...
	mkdir "!goodCheckFolder!Logs" >NUL
)

::Writing to log and handling errors
set "logFile=!logsFolder!\Log_GoodCheck_!_date!_!_time2!.txt"
echo GoodCheck !version! Log - !_date! - !_time!>"!logFile!"

if not exist "!logFile!" (
	set endedWithErrors=1
	echo WARNING: Problem encountered during logfile creation, attempting workaround...
	
	set "logFile=!goodCheckFolder!Log_%random%.txt"
	echo GoodCheck !version! Log - !_date! - !_time!>"!logFile!"
	
	if not exist "!logFile!" (
		set logFile=
		echo.
		echo WARNING: Can't create log file. Press any button to continue without one
		pause>NUL
	) else (
		echo Log file "!logFile!" successfully created
	)
) else (
	echo Log file "!logFile!" successfully created
)

call :WriteToConsoleAndToLog
call :WriteToConsoleAndToLog ---------------------
call :WriteToConsoleAndToLog


::====================================================================
::Taking variablies from env
call :WriteToConsoleAndToLog Reading external variables...

call :OverrideStringParam "!_gdpiFolderOverride!" gdpiFolderOverride
call :OverrideStringParam "!_zapretFolderOverride!" zapretFolderOverride
call :OverrideStringParam "!_ciaFolderOverride!" ciaFolderOverride

call :OverrideStringParam "!_fakeSNI!" fakeSNI
call :OverrideStringParam "!_fakeHexRaw!" fakeHexRaw
call :OverrideStringParam "!_fakeHexBytes!" fakeHexBytes
call :OverrideStringParam "!_payloadTLS!" payloadTLS
call :OverrideStringParam "!_payloadQuic!" payloadQuic

call :OverrideStringParam "!_curlMinTimeout!" curlMinTimeout
call :OverrideBooleanParam "!_curlAntiFreeze!" curlAntiFreeze

call :OverrideBooleanParam "!_dohEnabled!" dohEnabled
call :OverrideStringParam "!_curlDoH!" curlDoH[0]
call :OverrideBooleanParam "!_customCommonResolverEnabled!" customCommonResolverEnabled
call :OverrideStringParam "!_resolver!" resolver[0]
call :OverrideStringParam "!_customResolverIPv!" customResolverIPv

call :OverrideBooleanParam "!_skipAutoISPsGCS!" skipAutoISPsGCS
call :OverrideBooleanParam "!_skipAutoTLS12BreakageTest!" skipAutoTLS12BreakageTest

call :OverrideBooleanParam "!_outputMostSuccessfulStrategiesSeparately!" outputMostSuccessfulStrategiesSeparately
call :OverrideStringParam "!_mostSuccessfulStrategiesFile!" mostSuccessfulStrategiesFile

call :WriteToConsoleAndToLog
call :WriteToConsoleAndToLog ---------------------
call :WriteToConsoleAndToLog


::====================================================================
::Initial checks
call :WriteToConsoleAndToLog Initial Checks...

::Winver
for /f "tokens=4 delims=. " %%i in ('ver') do (set "winVersion=%%i")
call :WriteToConsoleAndToLog Windows major version: !winVersion!

::Checking up if we have admin rights
call :WriteToConsoleAndToLog Checking privilegies...
::Net session method not working for some people
rem net session >NUL 2>&1
fsutil dirty query %systemdrive% >NUL
if not !ERRORLEVEL!==0 (
	set endedWithErrors=2
	call :WriteToConsoleAndToLog
	call :WriteToConsoleAndToLog ERROR: This script requires elevated privilegies
	call :WriteToConsoleAndToLog
	call :WriteToConsoleAndToLog You need to right click on "%~n0%~x0" and choose "Run as administrator"
	goto EOF
)

::Checking up that checklist folder do exist
call :WriteToConsoleAndToLog Checking up if checklists folder do exist...
set "checkListFolder=!goodCheckFolder!!checkListFolder!\"
if not exist "!checkListFolder!" (
	set endedWithErrors=2
	call :WriteToConsoleAndToLog
	call :WriteToConsoleAndToLog ERROR: Can't find checklists folder
	goto EOF
)

::Checking up that strategies folder do exist
call :WriteToConsoleAndToLog Checking up if strategies folder do exist...
set "strategiesFolder=!goodCheckFolder!!strategiesFolder!\"
if not exist "!strategiesFolder!" (
	set endedWithErrors=2
	call :WriteToConsoleAndToLog
	call :WriteToConsoleAndToLog ERROR: Can't find strategies folder
	goto EOF
)

::Checking up that payloads folder do exist
call :WriteToConsoleAndToLog Checking up if payloads folder do exist...
set "payloadsFolder=!goodCheckFolder!!payloadsFolder!\"
if not exist "!payloadsFolder!" (
	set endedWithErrors=1
	call :WriteToConsoleAndToLog WARNING: Can't find payloads folder, continuing anyway...
) else (
	set payloadQuic="!payloadsFolder!!payloadQuic!"
	set payloadTLS="!payloadsFolder!!payloadTLS!"
)

::Setting subfolder based on processor architecture for future use
set "processorSubFolder=x86"
if "%PROCESSOR_ARCHITECTURE%"=="AMD64" (set "processorSubFolder=x86_64")
if defined PROCESSOR_ARCHITEW6432 (set "processorSubFolder=x86_64")

::Checking up that curl do exist
call :WriteToConsoleAndToLog Checking up if Curl do exist...
if defined curlFolder (
	set "curl=!goodCheckFolder!!curlFolder!\!processorSubFolder!\curl.exe"
	if not exist "!curl!" (
		call :WriteToConsoleAndToLog WARNING: Can't find Curl in it's folder...
		set "curl=!goodCheckFolder!curl.exe"
		::We are setting location for temp file here, since the system's curl located in system32 and we can't create tmp file there
		set "curlAntiFreezeTempFile=%temp%\!curlAntiFreezeTempFile!"
	)
)
if not exist "!curl!" (
	call :WriteToConsoleAndToLog WARNING: Can't find Curl in script folder...
	set "curl=curl.exe"
)
"!curl!" -V >NUL
if not !ERRORLEVEL!==0 (
	set endedWithErrors=2
	call :WriteToConsoleAndToLog
	call :WriteToConsoleAndToLog ERROR: Can't find Curl
	call :WriteToConsoleAndToLog
	call :WriteToConsoleAndToLog Download it at https://curl.se/ and put the content of /bin/ folder next to this script
	goto EOF
) else (
	call :WriteToConsoleAndToLog -----
	for /F "usebackq tokens=* delims=" %%i in (`"!curl!" -V`) do (call :WriteToConsoleAndToLog %%i)
	call :WriteToConsoleAndToLog -----
)

::Checking up network connectivity
call :WriteToConsoleAndToLog Checking up network connectivity...
::Apparently ICMP is blocked for some people, so we'll use curl here
rem ping -n 1 -w 2000 "!netConnTestURL!">NUL
"!curl!" -m !curlMinTimeout! -so NUL "!netConnTestURL!"
if not !ERRORLEVEL!==0 (
	call :WriteToConsoleAndToLog WARNING: Basic connectivity test failed, attempting insecure...
	"!curl!" -m !curlMinTimeout! --insecure -so NUL "!netConnTestURL!"
	if not !ERRORLEVEL!==0 (
		set endedWithErrors=2
		call :WriteToConsoleAndToLog
		call :WriteToConsoleAndToLog ERROR: No network connection. Make sure Curl aren't blocked by your firewall.
		goto EOF
	) else (
		set endedWithErrors=1
		set "curlExtraKeys=!curlExtraKeys! --insecure"
		call :WriteToConsoleAndToLog
		call :WriteToConsoleAndToLog WARNING: Network connection is present, but certificate verification is failed
		call :WriteToConsoleAndToLog
		call :WriteToConsoleAndToLog Either your firewall or antivirus are affecting connections, or ca-bundle is corrupted/unaccessible
		call :WriteToConsoleAndToLog
		echo Press any button to continue without certificate verifications...
		pause>NUL
	)
)

::Setting up DoH
if "!dohEnabled!"=="true" (
	call :WriteToConsoleAndToLog Setting up DNS-over-HTTPS resolver...
	for /L %%i in (0,1,15) do (
		if not "!curlDoH[%%i]!"=="" (
			call :WriteToConsoleAndToLog Trying "!curlDoH[%%i]!"...
			"!curl!" -m !curlMinTimeout! -so NUL "!curlDoH[%%i]!"
			if !ERRORLEVEL!==0 (
				call :WriteToConsoleAndToLog Resolver accessible
				set "curlExtraKeys=!curlExtraKeys! --doh-url !curlDoH!"
				goto BREAKRESOLVERSETUPLOOP
			)
		) else (
			call :WriteToConsoleAndToLog Can't find working DNS-over-HTTPS resolver
			set "dohEnabled=false"
			goto BREAKRESOLVERSETUPLOOP
		)
	)
)
:BREAKRESOLVERSETUPLOOP

::Setting up common resolver
if "!dohEnabled!"=="false" if "!customCommonResolverEnabled!"=="true" (
	if "!customResolverIPv!"=="6" (set "resolveType=AAAA") else (set "resolveType=A")
	
	call :WriteToConsoleAndToLog Setting up DNS resolver...
	for /L %%i in (0,1,15) do (
		if not "!resolver[%%i]!"=="" (
			call :WriteToConsoleAndToLog Pinging "!resolver[%%i]!"...
			ping -n 1 -w 2000 !resolver[%%i]!
			if !ERRORLEVEL!==0 (
				call :WriteToConsoleAndToLog Resolver accessible
				set "resolver=!resolver[%%i]!"
				goto BREAKRESOLVERSETUPLOOP2
			)
		) else (
			call :WriteToConsoleAndToLog Can't find working resolver
			set "customCommonResolverEnabled=false"
			goto BREAKRESOLVERSETUPLOOP2
		)
	)
)
:BREAKRESOLVERSETUPLOOP2

::Looking for executables
call :WriteToConsoleAndToLog Looking for executables...
::...for GDPI
if defined gdpiFolderOverride (
	call :LookForExe "!gdpiExeName!" "!gdpiFolderOverride!" "!gdpiName!" gdpiExeFullpath
	if not defined gdpiExeFullpath (
		call :LookForExe "!processorSubFolder!\!gdpiExeName!" "!gdpiFolderOverride!" "!gdpiName!" gdpiExeFullpath
	)
)
if not defined gdpiExeFullpath (
	call :LookForExe "!gdpiExeName!" "!goodCheckFolder!" "!gdpiName!" gdpiExeFullpath
)
if not defined gdpiExeFullpath (
	call :LookForExe "!gdpiExeName!" "!goodCheckFolder!!processorSubFolder!" "!gdpiName!" gdpiExeFullpath
)
if not defined gdpiExeFullpath (
	call :WriteToConsoleAndToLog Can't find !gdpiName! anywhere...
) else (
	::...Checking if it's outdated
	if "!winVersion!"=="10" (
		call :CalculateHash "!gdpiExeFullpath!" hash
		set confirmed=
		if !hash!==!hash_gdpi_64_023testbuild! (
			call :WriteToConsoleAndToLog You're using a 64-bit test build version with --fake-with-sni support
			set confirmed=1
			set "gdpiVersion=(newest test build detected)"
		)
		if !hash!==!hash_gdpi_86_023testbuild! (
			call :WriteToConsoleAndToLog You're using a 32-bit test build version with --fake-with-sni support
			set confirmed=1
			set "gdpiVersion=(newest test build detected)"
		)
		if !hash!==!hash_gdpi_64_testbuild_by_Decavoid! (
			call :WriteToConsoleAndToLog You're using a 64-bit test build version with --fake-with-sni support
			set confirmed=1
			set "gdpiVersion=(newest test build detected)"
		)
		if !hash!==!hash_gdpi_64_023rc32! (
			call :WriteToConsoleAndToLog You're using a 64-bit 0.2.3-rc3-2 version. It doesn't have --fake-with-sni support, but supports --fake-from-hex.
			set confirmed=1
			set "gdpiVersion=(last official build detected: no "--fake-with-sni" support)"
		)
		if !hash!==!hash_gdpi_86_023rc32! (
			call :WriteToConsoleAndToLog You're using a 32-bit 0.2.3-rc3-2 version. It doesn't have --fake-with-sni support, but supports --fake-from-hex.
			set confirmed=1
			set "gdpiVersion=(last official build detected: no "--fake-with-sni" support)"
		)
		if not defined confirmed (
			call :WriteToConsoleAndToLog You're using either an outdated or unknown version of "!gdpiName!" - it can cause problems
			set "gdpiVersion=(unknown or outdated version)"
		)
	)
)

::...for Zapret
if defined zapretFolderOverride (
	call :LookForExe "!zapretExeName!" "!zapretFolderOverride!" "!zapretName!" zapretExeFullpath
)
if not defined zapretExeFullpath (
	call :LookForExe "zapret-winws\!zapretExeName!" "!zapretFolderOverride!" "!zapretName!" zapretExeFullpath
)
if not defined zapretExeFullpath (
	call :LookForExe "!zapretExeName!" "!goodCheckFolder!" "!zapretName!" zapretExeFullpath
)
if not defined zapretExeFullpath (
	call :WriteToConsoleAndToLog Can't find "!zapretName!" anywhere...
) else (
	::...Checking if it's outdated
	call :CalculateHash "!zapretExeFullpath!" hash
	set confirmed=
	if "!winVersion!"=="10" (
		if !hash!==!hash_zapret_last! (
			call :WriteToConsoleAndToLog You're using the last version of "!zapretName!"
			set "zapretVersion=(last official build detected)"
			set confirmed=1
		)
		if not defined confirmed (
			call :WriteToConsoleAndToLog You're using either an outdated or unknown version of "!zapretName!" - it can cause problems
			set "zapretVersion=(unknown or outdated version)"
		)
	)
)

::...for ByeDPI
if defined ciaFolderOverride (
	call :LookForExe "!ciaExeName!" "!ciaFolderOverride!" "!ciaName!" ciaExeFullpath
)
if not defined ciaExeFullpath (
	call :LookForExe "!ciaExeName!" "!goodCheckFolder!" "!ciaName!" ciaExeFullpath
)
if not defined ciaExeFullpath (
	call :WriteToConsoleAndToLog Can't find "!ciaName!" anywhere...
) else (
	::...Checking if it's outdated
	call :CalculateHash "!ciaExeFullpath!" hash
	set confirmed=
	if "!winVersion!"=="10" (
		if !hash!==!hash_cia_last! (
			call :WriteToConsoleAndToLog You're using the last version of "!ciaName!"
			set "ciaVersion=(last official build detected)"
			set confirmed=1
		)
		if not defined confirmed (
			call :WriteToConsoleAndToLog You're using either an outdated or unknown version of "!ciaName!" - it can cause problems
			set "ciaVersion=(unknown or outdated version)"
		)
	)
)

call :WriteToConsoleAndToLog
call :WriteToConsoleAndToLog ---------------------
call :WriteToConsoleAndToLog


::====================================================================
::User choosing a test provider here
call :WriteToLog Script is ready.
:CHOICELOOP
cls

echo.
echo "!gdpiName!", "!zapretName!" and "!ciaName!" will be closed.
echo Their services will be stopped and removed.
echo.
echo.
echo Choose a program to test with:
echo.

::Lifehack for elements to be in order. Don't press shift+ABC during this choice at runtime - it will break stuff
set choiceTest=
if defined gdpiExeFullpath (
	echo Press [1] - test with "!gdpiName!" !gdpiVersion!
	set choiceTest=!choiceTest!1
) else (
	echo -
	set choiceTest=!choiceTest!A
)
if defined zapretExeFullpath (
	echo Press [2] - test with "!zapretName!" !zapretVersion!
	set choiceTest=!choiceTest!2
) else (
	echo -
	set choiceTest=!choiceTest!B
)
if defined ciaExeFullpath (
	echo Press [3] - test with "!ciaName!" !ciaVersion!
	set choiceTest=!choiceTest!3
) else (
	echo -
	set choiceTest=!choiceTest!C
)
set choiceTest=!choiceTest!0
echo.
echo Press [0] - cancel and exit

choice /C !choiceTest! /CS >NUL
set testWith=!ERRORLEVEL!

if !testWith!==4 (
	call :WriteToConsoleAndToLog
	call :WriteToConsoleAndToLog Cancelling...
	goto EOF
)

echo.
echo -
echo.

if !testWith!==1 (
	call :UserInputSubchoice "!gdpiName!" strategiesList
	if not "!strategiesList!"=="-1" (
		set "exeName=!gdpiExeName!"
		set "serviceName=!gdpiServiceName!"
		set "exeFullpath=!gdpiExeFullpath!"
		set "programName=!gdpiName!"
	) else (
		goto CHOICELOOP
	)
)
if !testWith!==2 (
	call :UserInputSubchoice "!zapretName!" strategiesList
	if not "!strategiesList!"=="-1" (
		set "exeName=!zapretExeName!"
		set "serviceName=!zapretServiceName!"
		set "exeFullpath=!zapretExeFullpath!"
		set "programName=!zapretName!"
	) else (
		goto CHOICELOOP
	)
)
if !testWith!==3 (
	call :UserInputSubchoice "!ciaName!" strategiesList
	if not "!strategiesList!"=="-1" (
		set "exeName=!ciaExeName!"
		set "serviceName=!ciaServiceName!"
		set "exeFullpath=!ciaExeFullpath!"
		set "programName=!ciaName!"
		
		::Showing warning message for ByeDPI
		echo.
		echo ATTENTION: "!ciaName!" functioning as a SOCKS Proxy. Make sure it isn't blocked by your firewall
		echo.
		echo Press any button to continue...
		pause>NUL
	) else (
		goto CHOICELOOP
	)
)

call :WriteToConsoleAndToLog
call :WriteToConsoleAndToLog Proceeding with "!programName!" and "!strategiesList!" strategy list...

call :WriteToConsoleAndToLog
call :WriteToConsoleAndToLog -------------------------------
call :WriteToConsoleAndToLog


::====================================================================
::Converting strategies list into an array
call :WriteToConsoleAndToLog Parsing strategy list...
call :WriteToConsoleAndToLog

set strategiesNum=-3
for /F "usebackq tokens=* eol=/" %%i in ("!strategiesList!") do (
	set /A strategiesNum+=1
	if !strategiesNum! LSS 0 (
		for /F "tokens=1,2* delims=#" %%j in ("%%i") do (
			if "%%j"=="_strategyCurlExtraKeys" (
				call :WriteToConsoleAndToLog Curl extra keys found: %%k
				set "curlExtraKeys=!curlExtraKeys! %%k"
			)
			if "%%j"=="_strategyExtraKeys" (
				call :WriteToConsoleAndToLog Strategy extra keys found: %%k
				call :WriteToConsoleAndToLog
				set "strategyExtraKeys=%%k"
			)
		)
	)
	if !strategiesNum! GEQ 0 (
		call :FormatStrategy "%%i" "!programName!" strategy
		call :WriteToConsoleAndToLog Reading strategies ^(!strategiesNum!^): !strategy!
		set "strategiesArray[!strategiesNum!]=!strategy!"
	)
)

call :WriteToConsoleAndToLog
call :WriteToConsoleAndToLog -------------------------------
call :WriteToConsoleAndToLog


::====================================================================
::Choosing a checklistlist
cls

echo.
echo "!gdpiName!", "!zapretName!" and "!ciaName!" will be closed.
echo Their services will be stopped and removed.
echo.
echo.
echo Choose a checklist:
echo.

set checkListFile=
call :UserInputCheckListChoice checkListFile

echo.
if "!checkListFile!"=="-1" (
	call :WriteToConsoleAndToLog
	call :WriteToConsoleAndToLog Cancelling...
	goto EOF
)
if not defined checkListFile (
	call :WriteToConsoleAndToLog Proceeding without a checklist...
) else (
	call :WriteToConsoleAndToLog Proceeding with a "!checkListFile!" checklist...
)

call :WriteToConsoleAndToLog
call :WriteToConsoleAndToLog -------------------------------
call :WriteToConsoleAndToLog


::====================================================================
::Looking for ISP's GCS
if "!skipAutoISPsGCS!"=="true" (
	call :WriteToConsoleAndToLog Skipping ISP's Google Cache Servers auto-test
	goto SKIPAUTOGCS
)

::Extracting our GGC cluster codename
call :ExtractClusterCodename clusterCodename
if defined clusterCodename (
	call :WriteToConsoleAndToLog Your cluster codename: !clusterCodename!
) else (
	set endedWithErrors=1
	call :WriteToConsoleAndToLog WARNING: Can't extract cluster codename
	call :WriteToConsoleAndToLog Make sure "!reportMappingURL[0]!" is accessible
	call :WriteToConsoleAndToLog
	echo Press any button to skip and continue...
	set "skipAutoISPsGCS=true"
	goto SKIPAUTOGCS
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

call :WriteToConsoleAndToLog Your Google Cache Server web address: !autoGCS!

:SKIPAUTOGCS

call :WriteToConsoleAndToLog
call :WriteToConsoleAndToLog -------------------------------
call :WriteToConsoleAndToLog


::====================================================================
::Creating a string for curl threaded request, reading and outputting sites from checklist to console and log
call :WriteToConsoleAndToLog Processing checklist...
call :WriteToConsoleAndToLog

set curlThreadsNum=0
set curlURL=
set domainIP=

if  "!skipAutoTLS12BreakageTest!"=="false" (
	set /A curlThreadsNum+=1
	set curlURL=!curlURL! !tls12TestURL! -o NUL
	call :WriteToConsoleAndToLog Site to check: !tls12TestURL! ^(TLS 1.2 Test site^)
	REM call :ResolveDomain !tls12TestURL! domainIP
	REM if defined domainIP (
		REM set curlURL=!curlURL! --resolve !tls12TestURL:https://=!:443:!domainIP!
	REM )
) else (
	call :WriteToConsoleAndToLog Skipping TLS 1.2 breakage auto-test
)

if "!skipAutoISPsGCS!"=="false" (
	set /A curlThreadsNum+=1
	set curlURL=!curlURL! !autoGCS! -o NUL
	call :WriteToConsoleAndToLog Site to check: !autoGCS! ^(Your ISPs Google Cache Server^)
	call :ResolveDomain !autoGCS! domainIP
	if defined domainIP (
		set curlURL=!curlURL! --resolve !autoGCS:https://=!:443:!domainIP!
	)
)

if exist "!checkListFile!" (
	for /F "usebackq tokens=* eol=/" %%i in ("!checkListFile!") do (
		set /A curlThreadsNum+=1
		call :CleanURL "%%i" url
		set curlURL=!curlURL! !url! -o NUL
		call :WriteToConsoleAndToLog Site to check: !url!
		call :ResolveDomain !url! domainIP
		if defined domainIP (
			set curlURL=!curlURL! --resolve !url:https://=!:443:!domainIP!
		)
	)
)
if  !curlThreadsNum!==1 (
	if "!dohEnabled!"=="true" (
		set /A curlThreadsNum+=1
		set curlURL=!curlURL! 0.0.0.0 -o NUL
		call :WriteToConsoleAndToLog Site to check: 0.0.0.0 ^(Workaround for Curl DoH problem^)
	)
)

if  !curlThreadsNum!==0 (
	set endedWithErrors=2
	call :WriteToConsoleAndToLog
	call :WriteToConsoleAndToLog ERROR: Nothing to check
	goto EOF
)

call :WriteToConsoleAndToLog


::====================================================================
::Estimating curl timeout: 2 sec for less than 100 threads, then +1 sec for every additional 100 threads
set curlParallelRequestTimeout=!curlMinTimeout!
for /L %%i in (100,100,300) do (
	if !curlThreadsNum! GTR %%i (
		set /A curlParallelRequestTimeout+=1
	) else (
		goto BREAKTIMEOUTESTIM
	)
)
:BREAKTIMEOUTESTIM

call :WriteToConsoleAndToLog Total: !curlThreadsNum! sites     Curl timeout: !curlParallelRequestTimeout! seconds

::====================================================================
::Choosing how many passes to do
set /A "_strategiesNum=!strategiesNum!+1"
set numberOfPasses=1

:USERCHOICENUMBEROFPASSES
cls

set /A "estimatedRawSeconds=!numberOfPasses!*!_strategiesNum!*(!curlParallelRequestTimeout!+1)"
call :SecondsToMinutesSeconds !estimatedRawSeconds! estimatedMinutes estimatedSeconds

echo.
echo "!gdpiName!", "!zapretName!" and "!ciaName!" will be closed.
echo Their services will be stopped and removed.
echo.
echo.
echo Estimated time for a test: !estimatedMinutes! minutes !estimatedSeconds! seconds
echo.
echo.
echo Choose how many passes to do: !numberOfPasses!
echo.
echo Press [1] - increase
echo Press [2] - decrease
echo.
echo Press [4] - accept
echo.
echo Press [0] - exit

::Using lifehack, don't press shift+F at runtime
set choises=1240
if !numberOfPasses!==1 (set "choises=1F40")
if !numberOfPasses!==9 (set "choises=F240")

choice /c !choises! /CS >NUL

set _choice=!ERRORLEVEL!

if !_choice!==1 (
	set /A numberOfPasses+=1
	goto USERCHOICENUMBEROFPASSES
)
if !_choice!==2 (
	set /A numberOfPasses-=1
	goto USERCHOICENUMBEROFPASSES
)
if !_choice!==3 (
	call :WriteToConsoleAndToLog
	call :WriteToConsoleAndToLog Proceeding with !numberOfPasses! passes...
)
if !_choice!==4 (
	call :WriteToConsoleAndToLog
	call :WriteToConsoleAndToLog Cancelling...
	goto EOF
)


call :WriteToLog Estimated time for a test: !estimatedMinutes! minutes !estimatedSeconds! seconds

call :WriteToConsoleAndToLog
call :WriteToConsoleAndToLog -------------------------------
call :WriteToConsoleAndToLog


::====================================================================
call :WriteToConsoleAndToLog Terminating active programs and services...

call :PurgeProgram "!gdpiExeName!"
call :PurgeProgram "!zapretExeName!"
call :PurgeProgram "!ciaExeName!"

call :PurgeService "!gdpiServiceName!"
call :PurgeService "!zapretServiceName!"
call :PurgeService "!ciaServiceName!"

call :PurgeWinDivert

call :WriteToConsoleAndToLog
call :WriteToConsoleAndToLog -------------------------------
call :WriteToConsoleAndToLog


::====================================================================
::Main testing loop
cls
echo.

::Time estimation
set /A "_oneCycleTime=!curlParallelRequestTimeout!+1"
set /A "estimatedRawSeconds=!numberOfPasses!*!_strategiesNum!*!_oneCycleTime!"
call :SecondsToMinutesSeconds !estimatedRawSeconds! estimatedMinutes estimatedSeconds

for /L %%i in (0,1,!strategiesNum!) do (

	call :WriteToConsoleAndToLog Testing ^(%%i/!strategiesNum!^): !strategiesArray[%%i]!
	
	REM echo curl !curlExtraKeys! -sm !curlParallelRequestTimeout! -w "%%{url}$%%{response_code} " -Z --parallel-immediate --parallel-max 300 !curlURL!
	REM pause
	
	call :WriteToConsoleAndToLog Starting up !programName!...
	start "!programName! - Launched through GoodCheck - Strategy %%i out of !strategiesNum!" /min "!exeFullpath!" !strategiesArray[%%i]!

	::Making request to see if servers are reachable. Timeout is neccessary to give program some time to load. Default timeout command is unreleable, using lifehack
	timeout /T 1 >NUL
	rem choice /C Q /D Q /CS /T 1 >NUL
	
	set lowestSuccesses=0
	for /L %%z in (1,1,!numberOfPasses!) do (
		
		title GoodCheck !version! - Testing in progress: %%i out of !strategiesNum! - Time remaining: !estimatedMinutes! minutes !estimatedSeconds! seconds
		
		::Time estimation
		set /A "estimatedRawSeconds=!estimatedRawSeconds!-!_oneCycleTime!"
		call :SecondsToMinutesSeconds !estimatedRawSeconds! estimatedMinutes estimatedSeconds
	
		set "result="
		
		pushd "!curl:curl.exe=!"
		
		::Workaround against curl not responding in time is applied here
		if "!curlAntiFreeze!"=="false" (
			call :WriteToConsoleAndToLog Starting up Curl...
			for /F "tokens=*" %%j in ('curl.exe !curlExtraKeys! -sm !curlParallelRequestTimeout! -w "%%{url}[ip:%%{remote_ip}]$%%{response_code} " -Z --parallel-immediate --parallel-max 300 !curlURL!') do (
				set "result=!result!%%j"
			)
			call :WriteToConsoleAndToLog Reading results...
		) else (
			if exist "!curlAntiFreezeTempFile!" (del "!curlAntiFreezeTempFile!")
			
			call :WriteToConsoleAndToLog Starting up Curl...
			start "Curling..." /min curl.exe !curlExtraKeys! -sm !curlParallelRequestTimeout! -w "%%output{>>"!curlAntiFreezeTempFile!"}%%{url}[ip:%%{remote_ip}]$%%{response_code} " -Z --parallel-immediate --parallel-max 300 !curlURL!
			
			call :WriteToConsoleAndToLog Waiting for Curl to do it's job...
			timeout /T !_oneCycleTime! >NUL
			rem choice /C Q /D Q /CS /T !_oneCycleTime! >NUL
			call :WriteToConsoleAndToLog Terminating Curl if it's still there...
			taskkill /T /F /IM "curl.exe" >NUL 2>&1
			call :WriteToConsoleAndToLog Reading results...
			for /F "usebackq delims=" %%x in ("!curlAntiFreezeTempFile!") do (set "result=%%x")
			if exist "!curlAntiFreezeTempFile!" (del "!curlAntiFreezeTempFile!")
		)
		
		popd
		
		::Parsing result
		set successes=0
		set tls12BreakageMessage=
		
		for %%j in (!result!) do (
			for /F "tokens=1,2 delims=$" %%p in ("%%j") do (
				if not "%%q"=="000" (
					set /A successes+=1
					call :WriteToConsoleAndToLog WORKING		%%p
				) else (
					call :WriteToConsoleAndToLog NOT WORKING	%%p
				)
				if "%%p"=="!tls12TestURL!" (
					if "%%q"=="000" (set "tls12BreakageMessage=   (TLS 1.2 Possible Breakage)")
				)
			)
		)
		
		if !successes! GTR !lowestSuccesses! (set lowestSuccesses=!successes!)
		
		call :WriteToConsoleAndToLog Successes - Pass %%z: !successes!/!curlThreadsNum!!tls12BreakageMessage!
		call :WriteToConsoleAndToLog
	)	
		
	::Writing to a variable for future use
	set "resultsArray[%%i]=!lowestSuccesses!/!strategiesArray[%%i]!!tls12BreakageMessage!"
	set "successesExist[!lowestSuccesses!]=1"
	
	call :WriteToConsoleAndToLog Terminating !programName!...
	call :PurgeProgram "!exeName!"
	rem call :PurgeService "!serviceName!"
	rem call :PurgeWinDivert
)

title GoodCheck !version! - Completed

call :WriteToConsoleAndToLog
call :WriteToConsoleAndToLog -------------------------------
call :WriteToConsoleAndToLog


::====================================================================
::Showcasing results and writing it to a file
set mostSuccessfulStrategies=0
for /L %%i in (0,1,!curlThreadsNum!) do (
	if defined successesExist[%%i] (
		call :WriteToConsoleAndToLog Strategies with %%i out of !curlThreadsNum! successes:
		for /L %%j in (0,1,!strategiesNum!) do (
			for /F "tokens=1,2 delims=/" %%k in ("!resultsArray[%%j]!") do (
				if "%%k"=="%%i" (
					if "!outputMostSuccessfulStrategiesSeparately!"=="true" (
						set mostSuccessfulStrategies=%%i
					)
					call :WriteToConsoleAndToLog %%l
				)
			)
		)
		call :WriteToConsoleAndToLog
	)
)
::Output most successful strategies separately
if "!outputMostSuccessfulStrategiesSeparately!"=="true" (
	if not defined _mostSuccessfulStrategiesFileName (
		for /F "tokens=1,2 delims=." %%p in ("!mostSuccessfulStrategiesFile!") do (
			set "mostSuccessfulStrategiesFile=%%p_!programName!.%%q"
		)
	)

	if exist "!mostSuccessfulStrategiesFile!" (
		del "!mostSuccessfulStrategiesFile!"
	)
	
	for /L %%j in (0,1,!strategiesNum!) do (
		for /F "tokens=1,2 delims=/" %%k in ("!resultsArray[%%j]!") do (
			if "%%k"=="!mostSuccessfulStrategies!" (
				echo %%l>>"!mostSuccessfulStrategiesFile!"
			)
		)
	)
)

call :WriteToConsoleAndToLog -------------------------------
call :WriteToConsoleAndToLog

if "!dohEnabled!"=="true" (
	call :WriteToConsoleAndToLog DNS-over-HTTPS resolver used: "!curlDoH!"
)
if "!dohEnabled!"=="false" if "!customCommonResolverEnabled!"=="true" (
	call :WriteToConsoleAndToLog Custom DNS resolver used: "!resolver!"
)

call :WriteToConsoleAndToLog

echo -------------------------------
echo.
echo Log saved to "!logFile!"
if "!outputMostSuccessfulStrategiesSeparately!"=="true" (
	echo.
	echo Most successful strategies saved to "!mostSuccessfulStrategiesFile!"
)
echo.

call :WriteToConsoleAndToLog -------------------------------

goto EOF


::====================================================================

:PurgeProgram
SetLocal EnableDelayedExpansion
set "taskName=%~1"
taskkill /T /F /IM "!taskName!" >NUL 2>&1
EndLocal
exit /b

:PurgeService
SetLocal EnableDelayedExpansion
set "serviceName=%~1"
net stop "!serviceName!" >NUL 2>&1
sc delete "!serviceName!" >NUL 2>&1
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
if "!message!"=="" (
	echo.
	if defined logFile (
		echo.>>"!logFile!"
	)
) else (
	echo !message!
	if defined logFile (
		echo !message!>>"!logFile!"
	)
)
EndLocal
exit /b

:WriteToLog
SetLocal EnableDelayedExpansion
set "message=%*"
if "!message!"=="" (
	if defined logFile (
		echo.>>"!logFile!"
	)
) else (
	if defined logFile (
		echo !message!>>"!logFile!"
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
			for /F "usebackq tokens=3 delims= " %%j in (`"!curl!" -sm !curlMinTimeout! !reportMappingURL[%%i]!`) do (
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
	call :WriteToConsoleAndToLog "!name!" is found at "!fullpath!"
) else (
	REM echo !name! NOT found at !fullpath!
	set "fullpath=!path!\!exe!"
	if exist "!fullpath!" (
		call :WriteToConsoleAndToLog "!name!" is found at "!fullpath!"
	) else (
		REM echo !name! NOT found at !fullpath!
		set fullpath=
	)
)
EndLocal && (set "%~4=%fullpath%")
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
set "program=%~2"
set "strategy=!strategyExtraKeys! !strategy!"
::mode for GDPI
if "!program!"=="!gdpiName!" (
	set "strategy=!strategy:FAKESNI=%fakeSNI%!"
	set "strategy=!strategy:FAKEHEX=%fakeHexRaw%!"
)
::mode for Zapret
if "!program!"=="!zapretName!" (
	set "strategy=!strategy:PAYLOADTLS=%payloadTLS%!"
	set "strategy=!strategy:PAYLOADQUIC=%payloadQuic%!"
)
::mode for ByeDPI
if "!program!"=="!ciaName!" (
	set "strategy=!strategy:FAKESNI=%fakeSNI%!"
	set "strategy=!strategy:PAYLOADTLS=%payloadTLS%!"
	set "strategy=!strategy:FAKEHEXBYTES=%fakeHexBytes%!"
)
EndLocal && (set "%~3=%strategy%")
exit /b

:CalculateHash
SetLocal EnableDelayedExpansion
set "file=%~1"
set count=0
set hash=0
for /F %%i in ('certutil -hashfile "!file!" MD5') do (
	set /A count+=1
	if !count!==2 (set hash=%%i)
)
EndLocal && (set "%~2=%hash%")
exit /b

:OverrideStringParam
SetLocal EnableDelayedExpansion
set "externalParam=%~1"
if defined externalParam (
	set "override=!externalParam!"
)
EndLocal && (
	if not "%override%"=="" (
		set "%~2=%override%"
	)
)
exit /b

:OverrideBooleanParam
SetLocal EnableDelayedExpansion
set "externalParam=%~1"
if defined externalParam (
	set "externalParam=!externalParam:T=t!"
	set "externalParam=!externalParam:R=r!"
	set "externalParam=!externalParam:U=u!"
	set "externalParam=!externalParam:E=e!"
	set "externalParam=!externalParam:F=f!"
	set "externalParam=!externalParam:A=a!"
	set "externalParam=!externalParam:L=l!"
	set "externalParam=!externalParam:S=s!"
	if not "!externalParam!"=="true" (
		if not "!externalParam!"=="false" (
			set endedWithErrors=1
			call :WriteToConsoleAndToLog WARNING: Can't override variable. Value "!externalParam!" is unacceptable.
		) else (
			set "override=!externalParam!"
		)
	) else (
		set "override=!externalParam!"
	)
)
EndLocal && (
	if not "%override%"=="" (
		set "%~2=%override%"
	)
)
exit /b

:SecondsToMinutesSeconds
SetLocal EnableDelayedExpansion
set "rawSeconds=%~1"
set /A minutes=!rawSeconds!/60
set /A seconds=!rawSeconds!-(!minutes!*60)
EndLocal && (
	set "%~2=%minutes%"
	set "%~3=%seconds%"
)
exit /b

:UserInputSubchoice
SetLocal EnableDelayedExpansion
set "strategiesSubfolder=%~1"
set count=0

pushd "!strategiesFolder!"
if exist "!strategiesSubfolder!" (
	pushd "!strategiesSubfolder!"
	for /F "usebackq delims=" %%i in (`dir /b /o:n`) do (
		if !count! LEQ !choiceArrayLen! (
			call set letter=%%choiceArray[!count!]%%
			set /A count+=1
			set "strategy[!count!]=%%~fi"
			echo Press [!letter!] - %%i
			set subChoice=!subChoice!!letter!
		)
	)
	if !count!==0 (
		echo No strategy list found for "!strategiesSubfolder!"
	)
	popd
) else (
	echo Subfolder for "!strategiesSubfolder!" not found
)
set /A count+=1
set subChoice=!subChoice!0
echo.
echo Press [0] - Back

choice /C !subChoice! >NUL
set userChoice=!ERRORLEVEL!
if !userChoice!==!count! (
	set finalList=-1
) else (
	set /A count-=1
	for /L %%i in (1,1,!count!) do (
		if %%i==!userChoice! (set "finalList=!strategy[%%i]!")
	)
)

popd
Endlocal && (set "%~2=%finalList%")
exit /b

:UserInputCheckListChoice
SetLocal EnableDelayedExpansion
set count=0

set /A count+=1
set checkListChoice=1!checkListChoice!
echo Press [1] - proceed without a checklist
echo.

pushd "!checkListFolder!"
for /F "usebackq delims=" %%i in (`dir /b /o:n`) do (
	if !count! LEQ !choiceArrayLen! (
		call set letter=%%choiceArray[!count!]%%
		set /A count+=1
		set "_checklist[!count!]=%%~fi"
		echo Press [!letter!] - %%i
		set checkListChoice=!checkListChoice!!letter!
	)
)
popd
if !count!==1 (
	call :WriteToConsoleAndToLog WARNING: No checklists are found in "!checkListFolder!"
	EndLocal && (set "%~1=")
	exit /b
)

set /A count+=1
set checkListChoice=!checkListChoice!0
echo.
echo Press [0] - cancel and exit

choice /C !checkListChoice! >NUL
set userChoice=!ERRORLEVEL!
if !userChoice!==!count! (
	set choosedList=-1
) else (
	set /A count-=1
	for /L %%i in (1,1,!count!) do (
		if %%i==!userChoice! (set "choosedList=!_checklist[%%i]!")
	)
)
Endlocal && (set "%~1=%choosedList%")
exit /b

:ResolveDomain
SetLocal EnableDelayedExpansion
set "resolvedIP="
if "!dohEnabled!"=="false" if "!customCommonResolverEnabled!"=="true" (
	set "domain=%~1"
	set "domain=!domain:https://=!"
	for /f "usebackq tokens=1,2* delims= " %%i in (`nslookup -type^=!resolveType! -timeout^=2 !domain! !resolver! 2^>^&1`) do (
		if "%%i"=="Addresses:" (set "resolvedIP=%%j")
		if "%%i"=="Address:" (
			if not "%%j"=="!resolver!" (set "resolvedIP=%%j")
		)
	)
	if defined resolvedIP (
		call :WriteToConsoleAndToLog Resolved: !domain! as !resolvedIP!
	) else (
		call :WriteToConsoleAndToLog Domain !domain! not resolved
	)
)
Endlocal && (set "%~2=%resolvedIP%")
exit /b


::====================================================================

:EOF
call :WriteToConsoleAndToLog

if !endedWithErrors!==0 (
	call :WriteToConsoleAndToLog Script ended without catched errors
)
if !endedWithErrors!==1 (
	call :WriteToConsoleAndToLog Script ended, but with some errors
)
if !endedWithErrors!==2 (
	call :WriteToConsoleAndToLog Script terminated with a critical error
)
echo.
echo.
echo Press any button to exit...
pause>NUL

EndLocal

title %comspec%
exit