USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prStoreTransactions_NewRecord_Status_Manage_Special]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prStoreTransactions_NewRecord_Status_Manage_Special]
as


update storetransactions
set TransactionStatus = 811
where ChainID in (44125, 44199)
and TransactionStatus = 0


--select * from chains

return
GO
