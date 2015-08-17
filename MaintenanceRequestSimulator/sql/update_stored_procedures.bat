::Author: Timothy Powell
::Date: 8/11/2015
::Description: This batch script updates all stored procedures with updates from the solution.
::    1.) Drop all stored procedures in datatrue main
::    2.) Reimport all procedures


SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

::Set Configuration 
SET dbhost=WinDev-PC
SET app_path=C:\Users\WinDev\Documents\GitHub\mr-test\MaintenanceRequestSimulator

sqlcmd -S %dbhost% -i "%app_path%\sql\drop_stored_procedures.sql"

::Create all MR tables in the DataTrue_EDI database
for %%G in (./edi/procedures/*Procedure.sql)^
do sqlcmd /S %dbhost% /d DataTrue_EDI -E -i "%app_path%\sql\edi\procedures\%%G"

::Create all MR tables in the DataTrue_Main database
for %%G in (./main/procedures/*Procedure.sql)^
do sqlcmd /S %dbhost% /d DataTrue_Main -E -i "%app_path%\sql\main\procedures\%%G"
