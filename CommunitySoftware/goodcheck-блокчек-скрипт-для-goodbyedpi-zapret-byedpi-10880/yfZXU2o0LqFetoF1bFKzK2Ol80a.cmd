::by Ori
chcp 65001
@echo off
cls

SetLocal EnableDelayedExpansion

::Setting up variables
::uzpkfa50vqlgb61wrmhc72xsnid83ytoje94
::0123456789abcdefghijklmnopqrstuvwxyz
set "ListA=u z p k f a 5 0 v q l g b 6 1 w r m h c 7 2 x s n i d 8 3 y t o j e 9 4 -"
set "ListB=0 1 2 3 4 5 6 7 8 9 a b c d e f g h i j k l m n o p q r s t u v w x y z -"

::Turning lists into arrays
set lettersArrayLen=0
for %%i in (%ListA%) do (
 set lettersArrayA[!lettersArrayLen!]=%%i
 set /A lettersArrayLen+=1
)
set lettersArrayLen=0
for %%i in (%ListB%) do (
 set lettersArrayB[!lettersArrayLen!]=%%i
 set /A lettersArrayLen+=1
)

::User input
echo.
set /P cluster="Cluster or URL: "

::Cleaning up input a bit
set "cluster=!cluster:https://=!"
set "cluster=!cluster:http://=!"
for /F "tokens=1 delims=/" %%i in ("!cluster!") do (
	set "cluster=%%i"
)
for /F "tokens=1 delims=." %%i in ("!cluster!") do (
	set "cluster=%%i"
)
REM for /F "tokens=1* delims=n" %%i in ("!cluster!") do (
	REM set "cluster=%%j"
REM )
REM set "cluster=!cluster:~1!"
REM echo Cleaned: !cluster!

::Converting cluster
for /L %%i in (0,1,99) do (
	set "letter=!cluster:~%%i,1!"
	if not defined letter (goto BREAKCONVCODENAME)
	
	for /L %%j in (0,1,!lettersArrayLen!) do (
		if !letter!==!lettersArrayA[%%j]! (set clusterCodename=!clusterCodename!!lettersArrayB[%%j]!)
		if !letter!==!lettersArrayB[%%j]! (set clusterCodenameInv=!clusterCodenameInv!!lettersArrayA[%%j]!)
	)
)
:BREAKCONVCODENAME

::howcaing result
echo.
echo Coverted: !clusterCodename!
echo Converted in reverse: !clusterCodenameInv!

EndLocal

pause>NUL

exit /b