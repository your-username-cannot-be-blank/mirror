@ECHO OFF
PUSHD "%~dp0"
color f1

:: !НЕ ТРОГАЙТЕ ТУТ НИЧЕГО! ::
set YTDB_YTPot=--dpi-desync=multisplit --dpi-desync-split-seqovl=1 --dpi-desync-split-pos=midsld+1
set YTDB_WinSZ=43 --hostlist="%~dp0lists\russia-youtubeGV.txt" --dpi-desync=multisplit --dpi-desync-split-seqovl=1 --dpi-desync-split-pos=midsld-1
set YTDB_DIS1=--ipset="%~dp0lists\russia-discord-ipset.txt" --dpi-desync=syndata --dpi-desync-fake-syndata="%~dp0fake\tls_clienthello_3.bin" --dpi-desync-autottl
set YTDB_DIS2=--hostlist="%~dp0lists\russia-discord.txt" --dpi-desync=fake,udplen --dpi-desync-udplen-increment=5 --dpi-desync-udplen-pattern=0xDEADBEEF --dpi-desync-fake-quic="%~dp0fake\quic_2.bin" --dpi-desync-repeats=7 --dpi-desync-cutoff=n2
set YTDB_DIS3=--dpi-desync=fake --dpi-desync-any-protocol --dpi-desync-cutoff=n3
:: ^^ !НЕ ТРОГАЙТЕ ТУТ НИЧЕГО! ^^ ::

:: Здесь можно включить дебаг-лог убрав rem и выключить, добавив rem ::
set YTDB_prog_log=--debug=@%~dp0log_debug.txt

:: Здесь можно включить другую стратегию для интерфейса Ютуба убрав rem и выключить, добавив rem ::
set YTDB_YTPot=--dpi-desync=fake,multisplit --dpi-desync-fooling=md5sig --dpi-desync-split-seqovl=2 --dpi-desync-split-pos=2 --dpi-desync-fake-tls="%~dp0fake\tls_clienthello_2.bin" --dpi-desync-autottl
rem set YTDB_YTPot=[Вы можете добавить сюда свою стратегию]

:: Здесь можно включить wssize для видео Ютуба [googlevideo.com] убрав rem и выключить, добавив rem ::
set YTDB_WinSZ=43 --wssize 1:6 --dpi-desync=fakedsplit --dpi-desync-split-seqovl=1 --dpi-desync-split-pos=midsld-1 --dpi-desync-fooling=md5sig,badseq
rem set YTDB_WinSZ=43 [Вы можете добавить сюда свою стратегию]

:: Здесь можно включить другую стратегию для Дискорда убрав rem и выключить, добавив rem ::
rem set YTDB_DIS1=--hostlist="%~dp0lists\russia-discord.txt" --dpi-desync=fake,multisplit --dpi-desync-split-pos=1,midsld --dpi-desync-fooling=md5sig,badseq --dpi-desync-fake-tls="%~dp0fake\tls_clienthello_4.bin" --dpi-desync-autottl
rem set YTDB_DIS1=--hostlist="%~dp0lists\russia-discord.txt" --dpi-desync=fake,fakedsplit --dpi-desync-fooling=badseq --dpi-desync-fake-tls="%~dp0fake\tls_clienthello_2.bin" --dpi-desync-repeats=6
rem YTDB_DIS1=[Вы можете добавить сюда свою стратегию (запуск Дискорда)]
rem set YTDB_DIS2=--hostlist="%~dp0lists\russia-discord.txt" --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic="%~dp0fake\quic_1.bin"
rem set YTDB_DIS3=--dpi-desync=fake --dpi-desync-any-protocol --dpi-desync-cutoff=d3 --dpi-desync-repeats=6
rem set YTDB_DIS3=--dpi-desync=fake --dpi-desync-any-protocol --dpi-desync-fake-unknown-udp=0xC30000000108 --dpi-desync-cutoff=n2
rem set YTDB_DIS3=[Вы можете добавить сюда свою стратегию (голос)]
:: Конец блока настройки стратегий ::

start "---] zapret: http,https,quic,youtube,discord [---" /min "%~dp0winws.exe" %YTDB_prog_log% ^
--wf-tcp=80,443 --wf-udp=443,50000-50090 ^
--filter-tcp=80,443 --hostlist="%~dp0lists\netrogat.txt" --new ^
--filter-tcp=443 --ipset="%~dp0lists\russia-youtube-rtmps.txt" --dpi-desync=syndata --dpi-desync-fake-syndata="%~dp0fake\tls_clienthello_4.bin" --dpi-desync-autottl --new ^
--filter-udp=443 --hostlist="%~dp0lists\russia-youtubeQ.txt" --dpi-desync=fake,udplen --dpi-desync-udplen-increment=2 --dpi-desync-fake-quic="%~dp0fake\quic_3.bin" --dpi-desync-cutoff=n3 --dpi-desync-repeats=2 --new ^
--filter-tcp=443 --hostlist="%~dp0lists\russia-youtube.txt" %YTDB_YTPot% --new ^
--filter-tcp=80 --hostlist="%~dp0lists\russia-blacklist.txt" --hostlist="%~dp0lists\myhostlist.txt" --dpi-desync=fake,multisplit --dpi-desync-fooling=md5sig --dpi-desync-autottl --new ^
--filter-tcp=443 --hostlist="%~dp0lists\russia-blacklist.txt" --hostlist="%~dp0lists\myhostlist.txt" --dpi-desync=fake,multisplit --dpi-desync-split-seqovl=1 --dpi-desync-split-pos=midsld-1 --dpi-desync-fooling=md5sig,badseq --dpi-desync-fake-tls="%~dp0fake\tls_clienthello_4.bin" --dpi-desync-autottl --new ^
--filter-tcp=443 %YTDB_DIS1% --new ^
--filter-udp=443 %YTDB_DIS2% --new ^
--filter-udp=50000-50090 %YTDB_DIS3% --new ^
--filter-tcp=4%YTDB_WinSZ% --new ^
--filter-tcp=443 --hostlist-auto="%~dp0lists\autohostlist.txt" --hostlist-exclude="%~dp0lists\netrogat.txt" --dpi-desync=fake,multidisorder --dpi-desync-split-seqovl=1 --dpi-desync-split-pos=midsld,1 --dpi-desync-fooling=md5sig,badseq --dpi-desync-fake-tls="%~dp0fake\tls_clienthello_4.bin" --dpi-desync-autottl
