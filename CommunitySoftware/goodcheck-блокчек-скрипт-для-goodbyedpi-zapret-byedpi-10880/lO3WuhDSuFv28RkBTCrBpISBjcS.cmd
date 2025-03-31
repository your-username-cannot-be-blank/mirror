@echo off
cls

SetLocal EnableDelayedExpansion

set "_list=CheckLists/default - googlevideo.txt"
set "_timeout=2"
set "_keys="

echo.
echo Parsing list...
if exist "!_list!" (
	for /F "usebackq tokens=* eol=/" %%i in ("!_list!") do (
		set "url=%%i"
		set "url=!url:https://=!"
		set "url=!url:http://=!"
		for /F "tokens=1 delims=/" %%j in ("!url!") do (
			set "url=https://%%j"
		)
		set urls=!urls! !url! -o NUL
		echo Site to check: !url!
	)
) else (
	echo Can't find sites list "!_list!"
)

:REPEAT

echo.
echo Making request...
for /F "tokens=*" %%i in ('curl !_keys! -sm !_timeout! -w "%%{response_code}$%%{url}[ip:%%{remote_ip}] " -Z --parallel-immediate --parallel-max 300 !urls!') do (
	set "result=%%i"
)

echo.
echo Showcasing results...
set successes=0
set total=0
for %%i in (!result!) do (
	for /F "tokens=1,2* delims=$" %%j in ("%%i") do (
		if "%%j"=="000" (
			echo NOT WORKING	%%k
		) else (
			echo WORKING		%%k
			set /A successes+=1
		)
		set /A total+=1
	)
)

echo.
echo Successes: !successes!/!total!

echo.
echo Press any button to repeat...
pause>NUL
goto REPEAT

EndLocal