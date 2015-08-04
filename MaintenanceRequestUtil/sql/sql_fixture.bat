::Set Configuration 
SET dbhost=WinDev-PC
SET app_path=C:\Users\WinDev\Documents\GitHub\mr-test

SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

mkdir c:\icontrol-mr
mkdir c:\icontrol-mr\data
mkdir c:\icontrol-mr\data-log

sqlcmd -S %dbhost% -i create_mr_databases.sql
ECHO *****FINISHED CREATING MAINTENANCE REQUEST DATABASES******

::Pull directly from


for %%G in (./edi/*Table.sql) do sqlcmd /S %dbhost% /d DataTrue_EDI -E -i "%app_path%/sql/edi/%%G"
for %%G in (./main/*Table.sql) do sqlcmd /S %dbhost% /d DataTrue_Main -E -i "%app_path%/sql/main/%%G"
for %%G in (./edi/*Function.sql) do sqlcmd /S %dbhost% /d DataTrue_EDI -E -i "%app_path%/sql/edi/%%G"
for %%G in (./main/*Function.sql) do sqlcmd /S %dbhost% /d DataTrue_Main -E -i "%app_path%/sql/main/%%G"
for %%G in (./edi/*Procedure.sql) do sqlcmd /S %dbhost% /d DataTrue_EDI -E -i "%app_path%/sql/edi/%%G"
for %%G in (./main/*Procedure.sql) do sqlcmd /S %dbhost% /d DataTrue_Main -E -i "%app_path%/sql/main/%%G"

::ECHO *****Finished Importing Testing SQL fixture and Procedures*****

:END
ENDLOCAL


ECHO ON
@EXIT /B 0
