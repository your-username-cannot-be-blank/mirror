::by Ori
@echo off
chcp 65001
title IP finder
cls


SetLocal EnableDelayedExpansion


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
::Setting up parameter for curl
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

::Forming IP array artificially
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
  echo Can't connect to web, exiting...
  pause>NUL
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
set /P website="Input URL to check: "
if "!website!"=="" (goto INPUTURL)
echo.

::Parsing user input
set "website=!website:https://=!"
set "website=!website:http://=!"
for /F "tokens=1 delims=/" %%i in ("!website!") do (set "website=%%i")

if not defined verbose (
 echo It may take some time...
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
echo List of IP found:
echo.
for /L %%i in (0,1,!successes!) do (
 echo !successesArray[%%i]!
)

echo.
echo Press 1 to exit
echo Press 2 to save IP list to a file
choice /C 12
echo.

::Saving to file if asked
if !ERRORLEVEL!==2 (
 PUSHD "%~dp0"
 
 echo !website!> "!website:.=_!.txt"
 echo.>> "!website:.=_!.txt"
 for /L %%i in (0,1,!successes!) do (
  echo !successesArray[%%i]!>> "!website:.=_!.txt"
 )
 echo Saved to "%~dp0!website:.=_!.txt"
 
 POPD
 
 echo.
 echo Press any button to exit...
 pause>NUL
)
::===================================================================================


:EOF
EndLocal


title %comspec%
exit /b