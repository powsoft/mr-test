USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtilCDCScripts]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtilCDCScripts]
as
select top 100 * from cdc.dbo_StoreTransactions_CT

select distinct __$operation from cdc.dbo_StoreTransactions_CT


select top 100 * from cdc.dbo_StoreTransactions_CT


select distinct __$operation from cdc.dbo_StoreTransactions_CT

select COUNT(*) from cdc.dbo_StoreTransactions_CT
GO
