@echo off

cd /d "%~dp0"
set "PKTWS_EXTRA=--dpi-desync-repeats=20"
FOR /F "tokens=* USEBACKQ" %%F IN (`..\cygwin\bin\cygpath -C OEM -a -m zapret\blog.sh`) DO (
SET P='%%F'
)

wscript ..\tools\elevator.vbs ..\cygwin\bin\bash -i "%P%"
