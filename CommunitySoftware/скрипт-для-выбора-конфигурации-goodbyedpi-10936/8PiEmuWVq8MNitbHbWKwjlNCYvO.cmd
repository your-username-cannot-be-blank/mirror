@echo off
color f0
title Select Configuration
chcp 1251
SetLocal EnableExtensions EnableDelayedExpansion
set "configsFile=%~dps0successfulConfigurations.txt"
set "asService=да нет"
call :GetChoice serviceFlag "%asService%" "2" "Установить goodbyedpi как службу?"
set blackListFlag=
set "blackLists='' 'myblacklist.txt' 'russia-blacklist.txt russia-youtube.txt' 'russia-blacklist.txt' 'russia-youtube.txt'"
cls
call :GetChoice blackList "%blackLists%" "1" "Разблокировать лишь сайты из блэклистов (если нет блэклиста - то все сайты)?"
if defined blackLists (
	for %%b in (%blackList%) do (
		set blackListFlag=!blackListFlag! --blacklist %~dps0%%b))
set dnsRedir=
cls
set /P dnsRedir=Использовать dns от yandex, чтобы обойти блокировку по ip? (по умолчанию=нет, лучше включить doh в браузере):
if defined dnsRedir (
	set dnsRedir=--dns-addr 77.88.8.8 --dns-port 1253 --dnsv6-addr 2a02:6b8::feed:0ff --dnsv6-port 1253)
set configsCount=0
for /F %%C in ('FIND /V /C "" ^<"!configsFile!"') do (
	set /A configsCount=%%C)
if "%configsCount%"=="0" (
	@echo Ошибка! В файле !configsFile! нет конфигураций!
	pause>nul
	exit /b)
(for /L %%i in (1,1,%configsCount%) do set /P config.%%i=)<"!configsFile!"
set configs=
for /L %%j in (1,1,%configsCount%) do (
	if defined config.%%j (
		set "configs=!configs! '!config.%%j!'"))
:repeat
cls
call :GetChoice config "%configs%" "1" "Выберите конфигурацию."
set "cmdLine=%config% %dnsRedir% %blackListFlag%"
set "cmdFileName=Configuration%config.N%"
if "%serviceFlag%"=="да" (
	set "cmdFileName=!cmdFileName!asService")
set "cmdFile=%~dps0!cmdFileName!.cmd"
call :SaveToCmd
cls
if exist "!cmdFile!" (
	start "" "%comspec%" /c "!cmdFile!"
	@echo Конфигурация N%config.N%=%config% запущена и сохранена в файл !cmdFileName!.cmd
	pause
) else (
	@echo Ошибка! Не удалось запустить конфигурацию N%config.N%=%config% и сохранить в файл !cmdFile!
	pause)
goto :repeat
EndLocal DisableDelayedExpansion

:GetChoice
SetLocal EnableDelayedExpansion
set values=%~2
set values=!values:'="!
set valueNDefault=%~3
set text=%~4
set count=0
for %%i in (%values%) do (
     set /A count +=1
	 @echo !count!: %%~i
     set value.!count!=%%~i)
set choiceN=%valueNDefault%
set /p choiceN=%text% Введите номер выбранного значения и нажмите Enter (по умолчанию=%valueNDefault%): 
set result=!value.%choiceN%!
EndLocal DisableDelayedExpansion & (
     set "%~1=%result%"
	 set "%~1.N=%choiceN%")
exit /b
		
:SaveToCmd
SetLocal EnableDelayedExpansion
goto :service_%serviceFlag%
:service_нет
(
@echo if "%%~1"=="" ^(
@echo pause
@echo mshta "vbscript:CreateObject("Shell.Application").ShellExecute("%%~fs0", "1", "", "runas", 1) & Close()"
@echo exit /b
@echo ^)
@echo set arch=x86
@echo if "%%PROCESSOR_ARCHITECTURE%%"=="AMD64" set arch=x86_64
@echo if defined PROCESSOR_ARCHITEW6432 set arch=x86_64
@echo taskkill /IM "goodbyedpi.exe" /F
@echo net stop "WinDivert"
@echo sc delete "WinDivert"
@echo start "" %%~dps0%%arch%%\goodbyedpi.exe %cmdLine%
@echo exit /b
)>"!cmdFile!"
goto :service_end
:service_да
(
@echo if "%%~1"=="" ^(
@echo pause
@echo mshta "vbscript:CreateObject("Shell.Application").ShellExecute("%%~fs0", "1", "", "runas", 1) & Close()"
@echo exit /b
@echo ^)
@echo set arch=x86
@echo if "%%PROCESSOR_ARCHITECTURE%%"=="AMD64" set arch=x86_64
@echo if defined PROCESSOR_ARCHITEW6432 set arch=x86_64
@echo taskkill /IM "goodbyedpi.exe" /F
@echo net stop "WinDivert"
@echo sc delete "WinDivert"
@echo set serviceName=GoodbyeDPI
@echo set cmdLine=%%~dps0%%arch%%\goodbyedpi.exe %cmdLine%
@echo net stop "%%serviceName%%"
@echo sc delete "%%serviceName%%"
@echo sc create "%%serviceName%%" binPath= "%%cmdLine%% start= "auto"
@echo sc description "%%serviceName%%" "Passive Deep Packet Inspection blocker and Active DPI circumvention utility"
@echo sc start "%%serviceName%%"
@echo exit /b
)>"!cmdFile!"
:service_end
EndLocal DisableDelayedExpansion
exit /b