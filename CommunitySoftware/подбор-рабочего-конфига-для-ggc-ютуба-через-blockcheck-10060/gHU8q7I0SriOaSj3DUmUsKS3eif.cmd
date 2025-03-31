::by Ori
@echo off
chcp 65001
title IP finder
cls


SetLocal EnableDelayedExpansion


::===================================================================================
set "fontDefault=[0m"
set "fontRed=[91m"
set "fontGreen=[92m"
set "fontBold=[1m"
set "fontYellow=[33m"
set "fontUnderline=[4m"
set "fontGrayish=[90m"
set "fontInvert=[7m"
::===================================================================================


::===================================================================================
::Setting up proxy, empty/undefied for no-proxy
rem set "proxy=socks5h://127.0.0.1:8086"

::Verbose mode; empty/undefied for quiet, 2 for extra verbose, any other value for standart verbose
set verbose=

::Emulation mode, without making actual requests; empty/undefied to turn off
set emulate=

::Number of threads, should be >0
set threads=20

::Curl parameters
set params=-s -k -m 2 -H "accept: application/dns-json"
::===================================================================================


::===================================================================================
::Setting up parameters for curl
if defined verbose (
 set "params=!params! -S"
)
if defined proxy (
 set "params=!params! --proxy !proxy!"
)
if !threads! GTR 1 (
 set "params=!params! -Z --parallel-immediate --parallel-max !threads!"
)

::Setting up resolvers
set "requestGoogleDNS=https://dns.google/resolve?name=website&type=A&edns_client_subnet="
set "requestDohLi=https://doh.li/dns-query?name=website&type=A&edns_client_subnet="
set "requestCloudflare=https://1.1.1.1/dns-query?name=website&type=A"
set "requestNextDNS=https://dns.nextdns.io/dns-query?name=website&type=A"
set "requestAdguardDNS=https://dns.adguard-dns.com/resolve?name=website&type=A"

::Forming up array of artificial IPs
set ipArrayLength=0
for /L %%i in (10,10,250) do (
 for /L %%j in (10,20,250) do (
  set /A ipArrayLength+=1
  set "ipArray[!ipArrayLength!]=%%i.%%j.0.0/16"
 )
)
::===================================================================================


::===================================================================================
::Checking if connected to web, skipping in emulate mode
if not defined emulate (
 ping -n 1 -w 2000 "w3.org">NUL
 if not "!ERRORLEVEL!"=="0" (
  echo.
  echo !fontRed!Can't connect to web, exiting...!fontDefault!
  goto EOF
 )
)

:INPUTURL
cls

::Showcaing some stuff
if defined verbose (
 if "!verbose!"=="2" (
  echo Using in extra verbose mode
 ) else (
  echo Using in verbose mode
 )
)
if defined emulate (echo Using in emulation mode)
if defined proxy (echo Using with proxy)
if "!verbose!"=="2" (echo Parameters for curl: !params!)
if "!verbose!"=="2" (echo IP addresses for subnet: !ipArrayLength!)

echo.

::User input
set /P website="!fontBold!Input URL to check: !fontDefault!"
if "!website!"=="" (goto INPUTURL)
echo.

::Parsing user input
set "website=!website:https://=!"
set "website=!website:http://=!"
for /F "tokens=1 delims=/" %%i in ("!website!") do (set "website=%%i")

if not defined verbose (
 echo !fontGrayish!It may take some time...!fontDefault!
 echo.
)
::===================================================================================


::===================================================================================
::Main part
set successes=-1
set response=

::One-time request for resolvers without subnet
if not defined emulate (
 ::Here additional resolvers can be added
 for /F "tokens=4* delims=[]" %%j in ('curl !params! "!requestCloudflare:website=%website%!"') do (set response=!response!CLOUDFLARE:%%j)
 for /F "tokens=4* delims=[]" %%j in ('curl !params! "!requestNextDNS:website=%website%!"') do (set response=!response!NEXTDNS:%%j)
 for /F "tokens=4* delims=[]" %%j in ('curl !params! "!requestAdguardDNS:website=%website%!"') do (set response=!response!ADGUARD:%%j)
) else (
 set response=!response!EMULATED:{"data":"0.0.0.0"}
)

::Loop for DNS with subnets
for /L %%i in (1,!threads!,!ipArrayLength!) do (
 title IP finder - Progress: %%i out of !ipArrayLength!
 
 ::Forming curl input for concurrent requests
 set requestParallelGoogleDNS=
 set requestParallelDohLi=
 set /A "num=%%i+!threads!-1"
 if "!verbose!"=="2" (
  echo Processing elements %%i-!num!
  echo.
 )
 for /L %%j in (%%i,1,!num!) do (
  if %%j LEQ !ipArrayLength! (
   ::Here additional resolvers can be added
   set requestParallelGoogleDNS=!requestParallelGoogleDNS! "!requestGoogleDNS:website=%website%!!ipArray[%%j]!"
   set requestParallelDohLi=!requestParallelDohLi! "!requestDohLi:website=%website%!!ipArray[%%j]!"
  )
 )
 if "!verbose!"=="2" (
  echo Complete request for GoogleDNS: !params!!requestParallelGoogleDNS!
  echo.
  echo Complete request for Doh.Li: !params!!requestParallelDohLi!
  echo.
 )
 
 ::Making request
 if not defined emulate (
  ::Here additional resolvers can be added
  for /F "tokens=4* delims=[]" %%j in ('curl !params!!requestParallelGoogleDNS!') do (set response=!response!GOOGLEDNS:%%j)
  ::This one kinda slow, but gives some more results
  for /F "tokens=4* delims=[]" %%j in ('curl !params!!requestParallelDohLi!') do (set response=!response!DOH.LI:%%j)
 )
 
 ::Parsing response 
 if defined response (
  if defined verbose (echo Response from DNS: !response!)
  set response=!response:{= !
  set response=!response:}= !
  
  for %%j in (!response!) do (
   if "!verbose!"=="2" (echo %%j)
   for /F "tokens=1,2 delims=:" %%k in ("%%j") do (
    if %%k=="data" (
	 ::Checking if valid IP
	 set "ipCandidate=%%~l"
     set "ipCandidate=!ipCandidate:~-1!"
     set valid=
	 for /L %%v in (0,1,9) do (
	  if "!ipCandidate!"=="%%v" (set valid=1)
	 )
	 if defined valid (
	  ::Checking for duplicates and adding new ones to the list
	  if defined verbose (echo IP found: %%~l  Checking for duplicates...)
	  set duplicates=
	  for /L %%z in (0,1,!successes!) do (
	   if "%%~l"=="!successesArray[%%z]!" (
	    if defined verbose (echo Duplicate found^^!)
        set duplicates=1
	   )
	  )
	  if not defined duplicates (
	   if defined verbose (echo Adding to list...)
	   set /A successes+=1
	   set successesArray[!successes!]=%%~l
	  )
	 )
	)
   )
  )
  set response=
  
 ) else (
  if defined verbose (echo No response from DNS)
 )
 if defined verbose (echo -------------)
)

title IP finder - Completed^^!
::===================================================================================


::===================================================================================
::Showcasing result
echo !fontUnderline!List of IP found!fontDefault! 
for /L %%i in (0,1,!successes!) do (
 echo !successesArray[%%i]!
)

echo.
echo Press !fontBold!1!fontDefault! to save
echo Press !fontBold!2!fontDefault! to test
echo Press !fontBold!3!fontDefault! to save and test
echo Press !fontBold!4!fontDefault! to exit
choice /C 1234>NUL
echo.
if %ERRORLEVEL%==4 (goto EOF)
if %ERRORLEVEL%==2 (goto TESTING)
if %ERRORLEVEL%==1 (set skipTesting=1)
::===================================================================================


::===================================================================================
::Saving to file
PUSHD "%~dp0"
 
echo !website!> "!website:.=_!.txt"
echo.>> "!website:.=_!.txt"
for /L %%i in (0,1,!successes!) do (
 echo !successesArray[%%i]!>> "!website:.=_!.txt"
)
echo !fontBold!Saved to:!fontDefault! "%~dp0!website:.=_!.txt"
 
POPD
)
echo.
if defined skipTesting (
 echo Press any button to exit...
 pause>NUL
 goto EOF
)
::===================================================================================


::===================================================================================
:TESTING
::Checking Curl version
for /F "tokens=1,2 delims= " %%i in ('curl -V') do (if "%%i"=="curl" set version=%%j)
for /F "tokens=1,2 delims=." %%i in ("!version!") do (set MajorVersion=%%i && set MinorVersion=%%j)
if !MajorVersion! GEQ 8 (if !MinorVersion! GEQ 10 (goto REALLYTESTING))
echo !fontRed!Curl outdated!fontDefault!
echo Obtain actual version at !fontUnderline!https://curl.se/!fontDefault! 
echo.
echo Press any button to exit...
pause>NUL
goto EOF

:REALLYTESTING
::Setting variables for a test
set "fakeSNI=fake.sni.com"
set testParams=-so NUL -m 2 -w "%%{time_starttransfer},%%{ssl_verify_result},%%{size_request},%%{size_header},%%{http_version},%%{exitcode},%%{redirect_url}"
set testRedirection=-so NUL -m 2 -w "%%{redirect_url}" "https://!website!"
set testParamsO1=--tlsv1.2 --tls-max 1.2 "https://!website!"
set testParamsO2=--tlsv1.3 --tls-max 1.3 "https://!website!"
set testParamsO3=--http3 "https://!website!"
set testParamsO4=-k --tlsv1.2 --tls-max 1.2 "https://!fakeSNI!"
set testParamsO5=-k --tlsv1.3 --tls-max 1.3 "https://!fakeSNI!"
set testParamsO6=-k --http3 "https://!fakeSNI!"
set "testModeO1=TLS 1.2          "
set "testModeO2=TLS 1.3          "
set "testModeO3=QUIC             "
set "testModeO4=TLS 1.2, fake SNI"
set "testModeO5=TLS 1.3, fake SNI"
set "testModeO6=QUIC, fake SNI   "

::Testing
for /L %%i in (0,1,!successes!) do (
 echo !fontUnderline!IP: !successesArray[%%i]!!fontDefault! 
 echo !fontGrayish!Mode			Time	Data Sent	Data Received	Redirect	SSL	HTTP Ver.	Code!fontDefault!
 for /L %%j in (1,1,6) do (
  for /F "tokens=1-7 delims=," %%k in ('curl !testParams! --connect-to ::!successesArray[%%i]! !testParamsO%%j!') do (
  
   set timeTaken=%%k
   if /I !timeTaken:.^=! NEQ 0 (set "timeTaken=!fontGreen!!timeTaken:~0,4!s!fontDefault!") else (set "timeTaken=!fontRed!FAIL !fontDefault!")
   
   if '%%q'=='https://!website!' (
    set "isRedirected=!fontGreen!NO  !fontDefault!"
   ) else (
    if '%%q'=='' (
     set "isRedirected=!fontGreen!NO  !fontDefault!"
    ) else (
     set "isRedirected=!fontRed!YES !fontDefault!"
	 set showRedirection=1
    )
   )
   
   if %%j LEQ 3 (
    if "%%l"=="0" (set "isSSLOk=!fontGreen!OK  !fontDefault!") else (set "isSSLOk=!fontRed!FAIL!fontDefault!")
   ) else (
    set "isSSLOk=!fontYellow!SKIP!fontDefault!"
	set "isRedirected=!fontYellow!SKIP!fontDefault!"
   )
   
   if "%%m"=="0" (set "isDataSent=!fontRed!NO !fontDefault!") else (set "isDataSent=!fontGreen!YES!fontDefault!")
   if "%%n"=="0" (set "isDataReceived=!fontRed!NO !fontDefault!") else (set "isDataReceived=!fontGreen!YES!fontDefault!")
   
   set httpVer=
   if "%%o"=="3" (set "httpVer=QUIC    ")
   if "%%o"=="0" (set "httpVer=-       ") 
   if not defined httpVer (
    if "%%o"=="2" (set "extraSpace=  ")
    if "%%j"=="3" (set "httpVer=!fontRed!HTTP/%%o!extraSpace!!fontDefault!")
	if "%%j"=="6" (set "httpVer=!fontRed!HTTP/%%o!extraSpace!!fontDefault!") 
	if not defined httpVer (set "httpVer=HTTP/%%o!extraSpace!")
   )
   
   set exitCode=
   if "%%p"=="0" (set "exitCode=!fontGreen!OK(%%p)!fontDefault!")
   if "%%p"=="95" (set "exitCode=!fontYellow!OK?(%%p)!fontDefault!")
   if "%%p"=="35" (set "exitCode=!fontRed!RESET(%%p)!fontDefault!")
   if "%%p"=="28" (set "exitCode=!fontRed!TIMEOUT(%%p)!fontDefault!")
   if "%%p"=="56" (set "exitCode=!fontRed!RESET(%%p)!fontDefault!")
   if "%%p"=="7" (set "exitCode=!fontRed!CANT CONNECT(%%p)!fontDefault!")
   if not defined exitCode (set "exitCode=!fontRed!%%p!fontDefault!")
   
   echo !testModeO%%j!	!timeTaken!	!isDataSent!		!isDataReceived!		!isRedirected!		!isSSLOk!	!httpVer!	!exitCode! 
  )
 )
 if defined showRedirection (
  for /F %%w in ('curl !testRedirection!') do (
   set redirectURL=%%w
   set redirectURL=!redirectURL:https://=!
   set redirectURL=!redirectURL:http://=!
   rem for /F "tokens=1 delims=/" %%z in ("!redirectURL!") do (set "redirectURL=%%z") 
   echo !fontBold!Redirected to:!fontDefault! !redirectURL!
  )
  set showRedirection=
 )
 echo.
)
echo Press any button to exit...
pause>NUL
::===================================================================================


:EOF
EndLocal

title %comspec%
exit /b