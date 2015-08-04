::Name: sql-config.bat
::Purpose: Initialize a minimal database to test and develop against the Maintenance Request System
::Directions - set the database name

SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: variables
SET database=MSSQLSERVER


sqlcmd -i create_mr_databases.sql

for %%G in (*.sql) do sqlcmd /S %1 /d DataTrue_EDI -E -i"%%G"
ECHO Finished with EDI, Now Main
for %%G in (*.sql) do sqlcmd /S %1 /d DataTrue_MAIN -E -i"%%G"


:END
ENDLOCAL
ECHO ON
@EXIT /B 0
