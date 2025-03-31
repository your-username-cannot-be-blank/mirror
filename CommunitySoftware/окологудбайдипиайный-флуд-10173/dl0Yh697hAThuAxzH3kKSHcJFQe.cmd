@ECHO OFF
PUSHD "%~dp0"
set _arch=x86
IF "%PROCESSOR_ARCHITECTURE%"=="AMD64" (set _arch=x86_64)
IF DEFINED PROCESSOR_ARCHITEW6432 (set _arch=x86_64)
PUSHD "%_arch%"

start "" goodbyedpi.exe -e 2 --native-frag --fake-from-hex 1603030135 --set-ttl 3 --blacklist ..\russia-blacklist.txt --blacklist ..\russia-youtube.txt

POPD
POPD
