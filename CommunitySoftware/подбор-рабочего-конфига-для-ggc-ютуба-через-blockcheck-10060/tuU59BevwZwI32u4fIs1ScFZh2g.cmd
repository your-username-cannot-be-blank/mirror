::by Ori
@echo off
chcp 65001
title IP finder
cls

::Setting up proxy or taking it from env if needed
rem set "proxy=socks5h://127.0.0.1:8086"
if defined proxy (
 set "proxy= --proxy %proxy%"
)

::Enabling verbose mode or taking it from env; any value is accepted
if not defined verbose (
 set verbose=
)

SetLocal EnableDelayedExpansion

::Lists of random domains from all around
rem set "domainsList=google.us google.nl google.pl"
rem set "ipList=50.50.50.50 100.100.100.100 150.150.150.150"

::Forming IP list artificially
for /L %%i in (10,10,250) do (
 for /L %%j in (10,20,250) do (
  set "ipList=!ipList!%%i.%%j.128.128 "
 )
)
set "ipList=!ipList:~0,-1!"

::Converting lists into arrays
set domainsArrayLength=-1
for %%i in (%domainsList%) do (
 set /A domainsArrayLength+=1
 set domainsArray[!domainsArrayLength!]=%%i
)
set domainsEndsHere=!domainsArrayLength!
for %%i in (%ipList%) do (
 set /A domainsArrayLength+=1
 set domainsArray[!domainsArrayLength!]=%%i
)

:INPUTURL
cls

if defined verbose (echo Using in verbose mode)
if defined proxy (echo Using with proxy)

echo.

::User input
set /P site="Input URL to check: "
if "%site%"=="" (goto INPUTURL)
echo.

if not defined verbose (
 echo It may take some time...
 echo.
)

::Main routine
set successes=-1
for /L %%i in (0,1,%domainsArrayLength%) do (
 ::Pinging site to find an IP for subnet and parsing result
 title Progress: %%i out of %domainsArrayLength%
 set "subnetIP="
 if %%i LEQ !domainsEndsHere! (
  for /F "tokens=1,3" %%j in ('ping -n 1 -w 2000 !domainsArray[%%i]!') do (
   if "%%j"=="Reply" (
    set "subnetIP=%%k"
    set subnetIP=!subnetIP:~0,-1!
   )
  )
 ) else (
  set "subnetIP=!domainsArray[%%i]!"
 )
 
 if defined subnetIP (
  ::Resolving DNS of a user-defined site while using custom subnet
  if defined verbose (echo Resolving DNS with subnet !subnetIP! ^(!domainsArray[%%i]!^))
  set response=
  for /F "tokens=4* delims=[]" %%j in ('curl!proxy! -skm 1 "https://dns.google/resolve?name=%site%&type=A&edns_client_subnet=!subnetIP!"') do (set response=%%j)
  ::Some other DNS resolvers? This one kinda slow, but gives additional results
  for /F "tokens=4* delims=[]" %%j in ('curl!proxy! -skm 1 "https://doh.li/dns-query?name=%site%&type=A&edns_client_subnet=!subnetIP!"') do (set response=!response!,DOHLI,%%j)
  if "!successes!"=="-1" (
   for /F "tokens=4* delims=[]" %%j in ('curl!proxy! -skm 1 -H "accept: application/dns-json" "https://1.1.1.1/dns-query?name=%site%&type=A"') do (set response=!response!,CLOUDFLARE,%%j)
   for /F "tokens=4* delims=[]" %%j in ('curl!proxy! -skm 1 -H "accept: application/dns-json" "https://dns.nextdns.io/dns-query?name=%site%&type=A"') do (set response=!response!,NEXTDNS,%%j)
   for /F "tokens=4* delims=[]" %%j in ('curl!proxy! -skm 1 -H "accept: application/dns-json" "https://dns.adguard-dns.com/resolve?name=%site%&type=A"') do (set response=!response!,ADGUARD,%%j)
  )
  if defined response (
   if defined verbose (echo Response from DNS: !response!)
   set response=!response:{= !
   set response=!response:}= !
  ) else (
   if defined verbose (echo No response from DNS)
  )
  ::Parsing response 
  for %%j in (!response!) do (
   rem echo %%j
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
	  ::Checking for duplicates and adding new ones in the list
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
 ) else (
  if defined verbose (echo Can't ping !domainsArray[%%i]! for subnet, skipping...)
 )

 if defined verbose (echo.)

)

title Completed^^!

::Showcasing result
echo List of IP found:
for /L %%i in (0,1,%successes%) do (
 echo !successesArray[%%i]!
)
 
EndLocal

echo.
echo That's all. Press any button to exit...
pause>NUL

title %comspec%

exit /b