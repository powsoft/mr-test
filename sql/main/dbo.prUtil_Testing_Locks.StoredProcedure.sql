USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Testing_Locks]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[prUtil_Testing_Locks]
as


SELECT spid, cmd, status, loginame, open_tran, 
datediff(s, last_batch, getdate ()) AS [WaitTime(s)]
FROM master..sysprocesses p WHERE open_tran > 0AND spid > 50 
AND datediff (s, last_batch, getdate ()) > 30 
ANd EXISTS (SELECT * FROM master..syslockinfo l WHERE req_spid = p.spid AND rsc_type <> 2) 

/*

select distinct workingstatus from StoreTransactions_working
where ChainID = 40393

select *
from StoreTransactions_working
where ChainID = 40393

select *
from StoreTransactions
where ChainID = 40393
and ReportedAllowance is not null
*/
GO
