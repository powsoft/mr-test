::Set Configuration 
SET dbhost=WinDev-PC
SET app_path=C:\Users\WinDev\Documents\GitHub\mr-test


SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

::TODO Add option to drop databases and start from scratch

::Create directories to store database files/logs
mkdir c:\icontrol-mr
mkdir c:\icontrol-mr\data
mkdir c:\icontrol-mr\data-log

::Run database creation scripts
sqlcmd -S %dbhost% -i create_mr_databases.sql
ECHO *****FINISHED CREATING MAINTENANCE REQUEST DATABASES******


::TODO: Pull full repository from bitbucket, then script the a copy of only the MR Procedures, Tables, etc.

::Create all MR tables in the DataTrue_EDI database
for %%G in (./edi/*Table.sql)^
do sqlcmd /S %dbhost% /d DataTrue_EDI -E -i "%app_path%\MaintenanceRequestUtil\sql\edi\%%G"

::Create all MR tables in the DataTrue_Main database
for %%G in (./main/*Table.sql)^
do sqlcmd /S %dbhost% /d DataTrue_Main -E -i "%app_path%\MaintenanceRequestUtil\sql\main\%%G"

::Create all MR functions in the DataTrue_EDI database
for %%G in (./edi/*Function.sql)^
do sqlcmd /S %dbhost% /d DataTrue_EDI -E -i "%app_path%\MaintenanceRequestUtil\sql\edi\%%G"

::Create all MR tables in the DataTrue_Main database
for %%G in (./main/*Function.sql)^
do sqlcmd /S %dbhost% /d DataTrue_Main -E -i "%app_path%\MaintenanceRequestUtil\sql\main\%%G"

::Create all MR tables in the DataTrue_EDI database
for %%G in (./edi/*Procedure.sql)^
do sqlcmd /S %dbhost% /d DataTrue_EDI -E -i "%app_path%\MaintenanceRequestUtil\sql\edi\%%G"

::Create all MR tables in the DataTrue_Main database
for %%G in (./main/*Procedure.sql)^
do sqlcmd /S %dbhost% /d DataTrue_Main -E -i "%app_path%\MaintenanceRequestUtil\sql\main\%%G"


ECHO *****Finished Importing Testing SQL fixture and Procedures*****

:END
ENDLOCAL


ECHO ON
@EXIT /B 0