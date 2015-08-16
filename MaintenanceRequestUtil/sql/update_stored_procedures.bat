::Author: Timothy Powell
::Date: 8/11/2015
::Description: This batch script updates all stored procedures with updates from the solution.
::    1.) Drop all stored procedures in datatrue main

SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

::Set output of this file to startup.log
command > c:\startup.log

::Set Configuration 
SET dbhost=WinDev-PC
SET app_path=C:\Users\WinDev\Documents\GitHub\mr-test

sqlcmd -S %dbhost% -i drop_stored_procedures.sql

::Create all MR tables in the DataTrue_EDI database
::for %%G in (./sql/edi/*Procedure.sql)^
::do sqlcmd /S %dbhost% /d DataTrue_EDI -E -i "%app_path%\MaintenanceRequestUtil\sql\edi\%%G"

::Create all MR tables in the DataTrue_Main database
::for %%G in (./sql/main/*Procedure.sql)^
::do sqlcmd /S %dbhost% /d DataTrue_Main -E -i "%app_path%\MaintenanceRequestUtil\sql\main\%%G"
