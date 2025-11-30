@echo off

set OUTPUT_FILE=%~1

set "ALL=%*"
call set "CMD=%%ALL:*%~1 =%%"

%CMD% > %OUTPUT_FILE%
