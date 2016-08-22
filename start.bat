@echo off
setlocal ENABLEDELAYEDEXPANSION

for %%e in (%PATHEXT%) do for %%i in (git.exe) do (
	SET filename=%%~$PATH:i
	set gitbash="!filename:~0,-12!\bin\bash.exe"
	if exist "!gitbash!" (
		"!gitbash!" --login -c "cd /d/pm && git pull && vagrant up"
		goto :eof
	)
)

:eof
