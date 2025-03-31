@ECHO OFF
PUSHD "%~dp0"

IF "%PROCESSOR_ARCHITECTURE%"=="AMD64" (set "os_arch=64")
IF "%PROCESSOR_ARCHITECTURE%"=="x86" (set "os_arch=32")
IF DEFINED PROCESSOR_ARCHITEW6432 (set "os_arch=64")

net stop GoodbyeDPI
net stop Zapret
sc delete GoodbyeDPI
sc delete Zapret
net stop WinDivert
sc delete Windivert

cls

if exist "%~dp0winws.exe" if exist "%~dp0WinDivert%os_arch%.sys" (
goto :ZapretStart
)
if not exist "%~dp0winws.exe" if not exist "%~dp0WinDivert%os_arch%.sys" (
goto :BITSDownload
)
goto :EOF

:BITSDownload
echo Preparing.....
bitsadmin /reset > nul
bitsadmin /create progdwnl > nul
bitsadmin /setpriority progdwnl HIGH > nul
bitsadmin /setproxysettings progdwnl NO_PROXY > nul
echo Start downloading cygwin1.dll from Zapret GitHub repo (may take some time).....
bitsadmin /transfer progdwnl https://github.com/bol-van/zapret/raw/66952453577ff602ca8fb82b19de1b4bcbfda58c/binaries/win%os_arch%/cygwin1.dll "%~dp0cygwin1.dll" > nul
if not exist "%~dp0cygwin1.dll" (
if exist "%Windir%\System32\curl.exe" (
echo Error!!! Can't download file. Trying CURL variant...
pause
goto :CURLDownload )
if not exist "%Windir%\System32\curl.exe" (
echo Error!!! Can't download files. Trying default browser variant...
pause
goto :BROWDownload )
)
echo Downloading cygwin1.dll..... Completed!
echo Start downloading WinDivert.dll from Zapret GitHub repo.....
bitsadmin /transfer progdwnl https://github.com/bol-van/zapret/raw/66952453577ff602ca8fb82b19de1b4bcbfda58c/binaries/win%os_arch%/WinDivert.dll "%~dp0WinDivert.dll" > nul
echo Downloading WinDivert.dll..... Completed!
echo Start downloading WinDivert%os_arch%.sys from Zapret GitHub repo (may be antivirus false or not-a-virus warning).....
bitsadmin /transfer progdwnl https://github.com/bol-van/zapret/raw/66952453577ff602ca8fb82b19de1b4bcbfda58c/binaries/win%os_arch%/WinDivert%os_arch%.sys "%~dp0WinDivert%os_arch%.sys" > nul
echo Downloading WinDivert%os_arch%.sys..... Completed!
echo Start downloading winws.exe from Zapret GitHub repo (may be antivirus false warning).....
bitsadmin /transfer progdwnl https://github.com/bol-van/zapret/raw/66952453577ff602ca8fb82b19de1b4bcbfda58c/binaries/win%os_arch%/winws.exe "%~dp0winws.exe" > nul
echo Downloading winws.exe..... Completed!
bitsadmin /cancel progdwnl > nul

echo.
echo Downloading completed
ping -n 5 127.0.0.1 > nul
goto :ZapretStart

:CURLDownload
echo Start downloading cygwin1.dll from Zapret GitHub repo (may take some time).....
curl -sOL https://github.com/bol-van/zapret/raw/66952453577ff602ca8fb82b19de1b4bcbfda58c/binaries/win%os_arch%/cygwin1.dll
echo Downloading cygwin1.dll..... Completed!
echo Start downloading WinDivert.dll from Zapret GitHub repo.....
curl -sOL https://github.com/bol-van/zapret/raw/66952453577ff602ca8fb82b19de1b4bcbfda58c/binaries/win%os_arch%/WinDivert.dll
echo Downloading WinDivert.dll..... Completed!
echo Start downloading WinDivert%os_arch%.sys from Zapret GitHub repo (may be antivirus false or not-a-virus warning).....
curl -sOL https://github.com/bol-van/zapret/raw/66952453577ff602ca8fb82b19de1b4bcbfda58c/binaries/win%os_arch%/WinDivert%os_arch%.sys
echo Downloading WinDivert%os_arch%.sys..... Completed!
echo Start downloading winws.exe from Zapret GitHub repo (may be antivirus false warning).....
curl -sOL https://github.com/bol-van/zapret/raw/66952453577ff602ca8fb82b19de1b4bcbfda58c/binaries/win%os_arch%/winws.exe
echo Downloading winws.exe..... Completed!

echo.
echo Downloading completed
ping -n 5 127.0.0.1 > nul
goto :ZapretStart

:BROWDownload
echo Start downloading cygwin1.dll from Zapret GitHub repo via default browser.....
start https://github.com/bol-van/zapret/raw/66952453577ff602ca8fb82b19de1b4bcbfda58c/binaries/win%os_arch%/cygwin1.dll
echo Wait for downloading in browser completed, then...
pause
echo Downloading cygwin1.dll..... Completed!
echo Start downloading WinDivert.dll from Zapret GitHub repo via default browser.....
start https://github.com/bol-van/zapret/raw/66952453577ff602ca8fb82b19de1b4bcbfda58c/binaries/win%os_arch%/WinDivert.dll
echo Wait for downloading in browser completed, then...
pause
echo Downloading WinDivert.dll..... Completed!
echo Start downloading WinDivert%os_arch%.sys from Zapret GitHub repo via default browser (may be antivirus false or not-a-virus warning).....
start https://github.com/bol-van/zapret/raw/66952453577ff602ca8fb82b19de1b4bcbfda58c/binaries/win%os_arch%/WinDivert%os_arch%.sys
echo Wait for downloading in browser completed, then...
pause
echo Downloading WinDivert%os_arch%.sys..... Completed!
echo Start downloading winws.exe from Zapret GitHub repo via default browser (may be antivirus or browser false warning).....
start https://github.com/bol-van/zapret/raw/66952453577ff602ca8fb82b19de1b4bcbfda58c/binaries/win%os_arch%/winws.exe
echo Wait for downloading in browser completed, then...
pause
echo Downloading winws.exe..... Completed!
echo.
echo Trying to move all 4 files to YTDisBystro folder.....
if exist "%UserProfile%\Downloads\winws.exe" if exist "%UserProfile%\Downloads\WinDivert%os_arch%.sys" (
move /Y "%UserProfile%\Downloads\cygwin1.dll" "%~dp0" > nul
move /Y "%UserProfile%\Downloads\WinDivert.dll" "%~dp0" > nul
move /Y "%UserProfile%\Downloads\WinDivert%os_arch%.sys" "%~dp0" > nul
move /Y "%UserProfile%\Downloads\winws.exe" "%~dp0" > nul
echo Moving... Completed!
echo.
ping -n 5 127.0.0.1 > nul
goto :ZapretStart
)
if not exist "%UserProfile%\Downloads\winws.exe" if not exist "%UserProfile%\Downloads\WinDivert%os_arch%.sys" (
echo Error!!! Non-standart Download folder used. Or antivirus false detect deleted files.
echo (Restore and )Move all 4 files to YTDisBystro folder manually then...
pause
)

:ZapretStart
exit
