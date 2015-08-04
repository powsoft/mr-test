USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[zprTestCDCRetrieve]    Script Date: 06/25/2015 18:26:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[zprTestCDCRetrieve]
as


DECLARE @begin_time datetime, @end_time datetime, @from_lsn binary(10), @to_lsn binary(10);

SET @from_lsn = sys.fn_cdc_get_min_lsn(N'dbo_StoreTransactions');
SET @to_lsn = sys.fn_cdc_get_max_lsn();

print @from_lsn

print @to_lsn

--SELECT * FROM cdc.fn_cdc_get_net_changes_dbo_StoreTransactions(0x00000000000000060000, 0x000030CC00001B360001, 'all');
SELECT * FROM cdc.fn_cdc_get_net_changes_dbo_StoreTransactions(@from_lsn, @to_lsn, 'all')
WHERE     (ProductID = 865) AND (StoreID = 12)
return
GO
