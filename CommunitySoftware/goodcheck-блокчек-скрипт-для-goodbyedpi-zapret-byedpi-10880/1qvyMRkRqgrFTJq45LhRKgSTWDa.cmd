@ECHO OFF
PUSHD "%~dp0"
set _arch=x86
IF "%PROCESSOR_ARCHITECTURE%"=="AMD64" (set _arch=x86_64)
IF DEFINED PROCESSOR_ARCHITEW6432 (set _arch=x86_64)
PUSHD "%_arch%"

start "" goodbyedpi.exe -e 2 --fake-with-sni www.google.com --native-frag --wrong-chksum --frag-by-sni --blacklist ..\russia-youtube.txt

POPD
POPD
