@echo off

cd /d "%~dp0"
set "PKTWS_EXTRA=--dpi-desync-fake-tls=tls_clienthello_www_google_com.bin --dpi-desync-fake-quic=quic_initial_google_com.bin"
FOR /F "tokens=* USEBACKQ" %%F IN (`..\cygwin\bin\cygpath -C OEM -a -m zapret\blog.sh`) DO (
SET P='%%F'
)

wscript ..\tools\elevator.vbs ..\cygwin\bin\bash -i "%P%"
