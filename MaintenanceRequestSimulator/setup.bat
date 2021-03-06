::Author: Timothy Powell
::Date: 8/08/2015
::Description: This batch script initializes the MR-QA development environment.
::    1.) Creates directories where DataTrue_EDI and DataTrue_Main data logs will be stored
::    2.) Creates databases, imports tables first, then functions, then procedures.
::    3.) TODO: Updates
SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

::Set output of this file to startup.log
::

::Set Configuration 
SET dbhost=WinDev-PC
SET app_path=C:\Users\WinDev\Documents\GitHub\mr-test\MaintenanceRequestSimulator


::TODO Add option to drop databases and start from scratch

::Create directories to store database files/logs
mkdir c:\icontrol-mr
mkdir c:\icontrol-mr\data
mkdir c:\icontrol-mr\data-log
::Application Log
mkdir c:\icontrol-mr\log

ECHO *****Dropping MR_Databases******
::Run database deletion scripts
sqlcmd -S %dbhost% -i .\sql\drop_mr_databases.sql

::Run database creation scripts
sqlcmd -S %dbhost% -i .\sql\create_mr_databases.sql
ECHO *****FINISHED CREATING MAINTENANCE REQUEST DATABASES******


::TODO: Pull full repository from bitbucket, then script the a copy of only the MR Procedures, Tables, etc.

::Create all MR tables in the DataTrue_EDI database
for %%G in (./sql/edi/*Table.sql)^
do sqlcmd /S %dbhost% /d DataTrue_EDI -E -i "%app_path%\sql\edi\%%G"

::Create all MR tables in the DataTrue_Main database
for %%G in (./sql/main/*Table.sql)^
do sqlcmd /S %dbhost% /d DataTrue_Main -E -i "%app_path%\sql\main\%%G"

::Create all MR functions in the DataTrue_EDI database
for %%G in (./sql/edi/*Function.sql)^
do sqlcmd /S %dbhost% /d DataTrue_EDI -E -i "%app_path%\sql\edi\%%G"

::Create all MR tables in the DataTrue_Main database
for %%G in (./sql/main/*Function.sql)^
do sqlcmd /S %dbhost% /d DataTrue_Main -E -i "%app_path%\sql\main\%%G"

::Create all MR tables in the DataTrue_EDI database
for %%G in (./sql/edi/procedures/*Procedure.sql)^
do sqlcmd /S %dbhost% /d DataTrue_EDI -E -i "%app_path%\sql\edi\procedures\%%G"

::Create all MR tables in the DataTrue_Main database
for %%G in (./sql/main/procedures/*Procedure.sql)^
do sqlcmd /S %dbhost% /d DataTrue_Main -E -i "%app_path%\sql\main\procedures\%%G"


ECHO *****Finished Importing Testing SQL fixture and Procedures*****

:END
ENDLOCAL


ECHO ON
@EXIT /B 0