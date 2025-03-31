::by Ori
::todo  output to a file with test results, ru translation maybe, form dns requests like a browser
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
::Setting up proxy, empty/undefined for no-proxy
rem set "proxy=socks5h://127.0.0.1:8086"

::Verbose mode; empty/undefined for quiet, 2 for extra verbose, any other value for standart verbose
set verbose=

::Emulation mode, without making actual requests; empty/undefined to turn off, any value to turn on
set emulate=

::Threads, should be a reasonable number >0
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
  echo !fontRed!Can't connect to network!fontDefault!
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
set /P website="!fontBold!Input URL to resolve: !fontDefault!"
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
 for /F "tokens=*" %%i in ('curl !params! "!requestCloudflare:website=%website%!"') do (set response=!response!_____CLOUDFLARE_____%%i)
 for /F "tokens=*" %%i in ('curl !params! "!requestNextDNS:website=%website%!"') do (set response=!response!_____NEXTDNS_____%%i)
 for /F "tokens=*" %%i in ('curl !params! "!requestAdguardDNS:website=%website%!"') do (set response=!response!_____ADGUARD_____%%i)
) else (
 set response=EMULATED[{"name":"example.com"},{"data":"0.0.0.0"},"name":"duplicateexample.com"},{"data":"0.0.0.0"},"name":"invalidexample.com"},{"data":"999.999.999"},"name":"weirdexample.com"},{"data":"\\NOT.AN.IP.AT.ALL"}]
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
  for /F "tokens=*" %%j in ('curl !params!!requestParallelGoogleDNS!') do (set response=!response!_____GOOGLEDNS_____%%j)
  ::This one kinda slow, but gives some more results
  for /F "tokens=*" %%j in ('curl !params!!requestParallelDohLi!') do (set response=!response!_____DOHLI_____%%j)
 )
 
 ::Parsing response 
 if defined response (
  if defined verbose (echo Response from DNS: !response!)
  set "response=!response:,= !"
  set "response=!response:[= !"
  set "response=!response:{= !"
  set "response=!response:(= !"
  set "response=!response:]= !"
  set "response=!response:}= !"
  set "response=!response:)= !"
  
  for %%j in (!response!) do (
   if "!verbose!"=="2" (echo %%j)
   
   set "item=%%j"
   set "item=!item:~0,6!"
   
   ::Processing "data" item, usually IP
   if !item!=="data" (
    set /A "total=!total!+1"
    for /F "tokens=2 delims=:" %%k in ("%%j") do (
	 if defined verbose (echo ===== Potential IP found %%~k)
	 ::Checking if valid IP
	 set valid=
	 for /F "tokens=4,5* delims=." %%v in ("%%~k") do (
      if "%%w"=="" (
	   set valid=1
	  )
	 )
	 ::Checking for duplicates and adding new ones to the list
	 if defined valid (
	  set duplicates=
	  for /L %%z in (0,1,!successes!) do (
	   if "%%~k"=="!successesArray[%%z]!" (
	    if defined verbose (echo Duplicate^^!)
        set duplicates=1
	   )
	  )
	  if not defined duplicates (
	   set /A successes+=1
	   set successesArray[!successes!]=%%~k
	   if defined verbose (echo Added to the list in position !successes!)
	  )
	 ) else (
	  if defined verbose (echo Not a valid IP^^!)
	 )
	)
   ) 
  )
  set response=
  
 ) else (
  if defined verbose (echo No response from DNS)
 )
 if defined verbose (echo --------------------------)
)

title IP finder - Completed^^!
::===================================================================================


::===================================================================================
::Showcasing result
if defined verbose (echo Total answers from DNS: !total!)
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

echo.
if defined skipTesting (goto EOF)
timeout /t 2 /NOBREAK >NUL
::===================================================================================


::===================================================================================
:TESTING
::Checking Curl version
for /F "tokens=1,2 delims= " %%i in ('curl -V') do (if "%%i"=="curl" set version=%%j)
for /F "tokens=1,2 delims=." %%i in ("!version!") do (set /A version=%%i*100+%%j)
if !version! LSS 810 (
 echo.
 echo !fontRed!Curl outdated!fontDefault!
 echo Obtain actual version at !fontUnderline!https://curl.se/!fontDefault! 
 echo.
 goto EOF
)

::Setting variables for a test
set "fakeSNI=fake.sni.com"
set testParams=-so NUL -m 2 -w "%%{time_connect},%%{ssl_verify_result},%%{size_request},%%{size_header},%%{http_version},%%{exitcode},%%{response_code},%%{redirect_url}"
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
set "testModeO4=TLS 1.2  fake SNI"
set "testModeO5=TLS 1.3  fake SNI"
set "testModeO6=QUIC     fake SNI"

if defined proxy (
 set "testParams=!testParams! --proxy !proxy!"
)

::Testing
for /L %%i in (0,1,!successes!) do (
 echo.
 echo !fontUnderline!IP: !successesArray[%%i]!!fontDefault! 
 
 ::Pinging
 ping -n 1 -w 2000 "!successesArray[%%i]!">NUL
 if "!ERRORLEVEL!"=="0" (set "isPingable=!fontGreen!YES!fontDefault!") else (set "isPingable=!fontRed!NO !fontDefault!")
 
 ::Formatting this was painful
 echo Ping: !isPingable!!fontGrayish!			Data	Data	SSL  	Re-   	HTTP	Exit		Response!fontDefault!
 echo !fontGrayish!Mode			Time	sent	get 	check	direct	Ver.	code		code!fontDefault!
 
 ::Curling
 for /L %%j in (1,1,6) do (
  for /F "tokens=1-8 delims=," %%k in ('curl !testParams! --connect-to ::!successesArray[%%i]! !testParamsO%%j!') do (
   
   set isTestFailed=
   
   ::Checking latency
   set timeTaken=%%k
   if /I !timeTaken:.^=! NEQ 0 (
    set "timeTaken=!fontGreen!!timeTaken:~0,5!s!fontDefault!" 
   ) else (
	set "timeTaken=!fontRed!FAIL  !fontDefault!"
	set isTestFailed=1
   )
   
   ::Checking sent bytes
   if not defined isTestFailed (
    if not "%%m"=="0" (
     set "isDataSent=!fontGreen!YES!fontDefault!"
    ) else (
     set "isDataSent=!fontRed!NO !fontDefault!"
	 set isTestFailed=1
    )
   ) else (
    set "isDataSent=!fontRed!-  !fontDefault!"
   )
   
   ::Checking recv bytes
   if not defined isTestFailed (
    if not "%%n"=="0" (
     set "isDataReceived=!fontGreen!YES!fontDefault!"
    ) else (
     set "isDataReceived=!fontRed!NO !fontDefault!"
 	 set isTestFailed=1
    )
   ) else (
    set "isDataReceived=!fontRed!-  !fontDefault!"
   )
   
   ::SSL verification
   if not defined isTestFailed (
    if "%%l"=="0" (set "isSSLOk=!fontGreen!OK  !fontDefault!")
	if %%j GTR 3 (set "isSSLOk=!fontYellow!SKIP!fontDefault!")
	if not defined isSSLOk (
	 set "isSSLOk=!fontRed!FAIL!fontDefault!"
	 set isTestFailed=1
    )
   ) else (
    set "isSSLOk=!fontRed!-   !fontDefault!"
   )
   
   ::Redirect test, skipping for fake sni tests
   if not defined isTestFailed (
    if %%j LEQ 3 (
     set "redirectWebsite=%%r"
     if defined redirectWebsite (
      set "redirectWebsite=!redirectWebsite:https://=!"
      set "redirectWebsite=!redirectWebsite:http://=!"
	  set "redirectWebsite=!redirectWebsite:www.=!"
      for /F "tokens=1 delims=/" %%z in ("!redirectWebsite!") do (set "redirectWebsite=%%z")
	  if not "!redirectWebsite!"=="!website:www.=!" (
	   set "isRedirected=!fontRed!YES !fontDefault!"
	   set showRedirection=1
	  ) else (
	   set "isRedirected=!fontYellow!SAFE!fontDefault!"
	  )
     ) else (
	  set "isRedirected=!fontGreen!NO  !fontDefault!"
	 )
    ) else (
     set "isRedirected=!fontYellow!SKIP!fontDefault!"
    )
   ) else (
    set "isRedirected=!fontRed!-   !fontDefault!"
   )
   
   ::HTTP version check
   if not defined isTestFailed (
   	if "%%o"=="0" (set "httpVer=!fontRed!ERROR !fontDefault!")
    if "%%o"=="3" (set "httpVer=!fontGreen!QUIC  !fontDefault!")
	set "is1245=!fontGreen!"
    if "%%j"=="3" (set "is1245=!fontRed!")
	if "%%j"=="6" (set "is1245=!fontRed!")
    if "%%o"=="1.1" (set "httpVer=!is1245!H/1.1!fontDefault!")
    if "%%o"=="2" (set "httpVer=!is1245!HTTP/2!fontDefault!")
   ) else (
    set "httpVer=!fontRed!-     !fontDefault!"
   )
   
   ::Response code
   if not defined isTestFailed (
    set responseCode=
	if "%%q"=="200" (set "responseCode=%%q OK                   ")
	if "%%q"=="204" (set "responseCode=%%q No Content           ")
	if "%%q"=="301" (set "responseCode=%%q Moved Permanently    ")
	if "%%q"=="302" (set "responseCode=%%q Found                ")
	if "%%q"=="307" (set "responseCode=%%q Temporary Redirect   ")
	if "%%q"=="308" (set "responseCode=%%q Permanent Redirect   ")
	if "%%q"=="400" (set "responseCode=%%q Bad Request          ")
	if "%%q"=="401" (set "responseCode=%%q Unauthorized         ")
	if "%%q"=="403" (set "responseCode=%%q Forbidden            ")
	if "%%q"=="404" (set "responseCode=%%q Not Found            ")
	if "%%q"=="405" (set "responseCode=%%q Method Not Allowed   ")
	if "%%q"=="406" (set "responseCode=%%q Not Acceptable       ")
	if "%%q"=="408" (set "responseCode=%%q Request Timeout      ")
	if "%%q"=="413" (set "responseCode=%%q Payload Too Large    ")
	if "%%q"=="414" (set "responseCode=%%q URI Too Long         ")
	if "%%q"=="429" (set "responseCode=%%q Too Many Requests    ")
	if "%%q"=="500" (set "responseCode=%%q Internal Server Error")
	if "%%q"=="502" (set "responseCode=%%q Bad Gateway          ")
	if "%%q"=="503" (set "responseCode=%%q Service Unavailable  ")
	if "%%q"=="504" (set "responseCode=%%q Gateway Timeout      ")
	
    if not defined responseCode (set "responseCode=%%q                      ")
   ) else (
    set "responseCode=!fontRed!-                        !fontDefault!"
   )
   
   ::Exit code
   set exitCode=
   if "%%p"=="0" (set "exitCode=!fontGreen!%%p OK       !fontDefault!")
   if "%%p"=="7" (set "exitCode=!fontRed!%%p CANT CONN!fontDefault!")
   if "%%p"=="8" (set "exitCode=!fontYellow!%%p FTP ERR  !fontDefault!")
   if "%%p"=="28" (set "exitCode=!fontRed!%%p TIMEOUT  !fontDefault!")
   if "%%p"=="35" (set "exitCode=!fontRed!%%p RESET    !fontDefault!")
   if "%%p"=="56" (set "exitCode=!fontRed!%%p RESET    !fontDefault!")
   if "%%p"=="95" (set "exitCode=!fontYellow!%%p h3GENERIC!fontDefault!")

   if not defined exitCode (set "exitCode=!fontRed!%%p          !fontDefault!")
   
   ::Showing result
   echo !testModeO%%j!	!timeTaken!	!isDataSent!	!isDataReceived!	!isSSLOk!	!isRedirected!	!httpVer!	!exitCode!	!responseCode!
  )
 )
 
 ::Showing redirection if found
 if defined showRedirection (
  for /F %%w in ('curl !testRedirection!') do (
   set redirectURL=%%w
   set redirectURL=!redirectURL:https://=!
   set redirectURL=!redirectURL:http://=!
   for /F "tokens=1 delims=/" %%z in ("!redirectURL!") do (set "redirectURL=%%z") 
   echo !fontUnderline!!fontGrayish!Redirected to:!fontDefault! !redirectURL!
  )
  set showRedirection=
  
 )
 echo.
)
::===================================================================================


:EOF
echo.
echo Press any button to exit...
pause>NUL

EndLocal

title %comspec%
exit /b