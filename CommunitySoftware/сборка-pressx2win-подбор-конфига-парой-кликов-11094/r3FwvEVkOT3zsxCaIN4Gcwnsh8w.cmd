if "%~1"=="" (
mshta "vbscript:CreateObject("Shell.Application").ShellExecute("%~fs0", "1", "", "runas", 1) & Close()"
cls
exit /b
)
set arch=x86
if "%PROCESSOR_ARCHITECTURE%"=="AMD64" set arch=x86_64
if defined PROCESSOR_ARCHITEW6432 set arch=x86_64
taskkill /IM "goodbyedpi.exe" /F
net stop "WinDivert"
sc delete "WinDivert"
set serviceName=GoodbyeDPI
set cmdLine=%~dps0%arch%\goodbyedpi.exe -e 2 -q --reverse-frag --wrong-chksum --frag-by-sni --fake-from-hex 1603030135010001310303424143facf5c983ac8ff20b819cfd634cbf5143c0005b2b8b142a6cd335012c220008969b6b387683dedb4114d466ca90be3212b2bde0c4f56261a9801 --fake-gen 10 --set-ttl 3 --max-payload   --blacklist C:\PROGRA~1\GOODBY~1\GOODBY~1.2\russia-blacklist.txt --blacklist C:\PROGRA~1\GOODBY~1\GOODBY~1.2\russia-youtube.txt
net stop "%serviceName%"
sc delete "%serviceName%"
sc create "%serviceName%" binPath= "%cmdLine%" start= "auto"
sc description "%serviceName%" "Passive Deep Packet Inspection blocker and Active DPI circumvention utility"
sc start "%serviceName%"
exit /b
