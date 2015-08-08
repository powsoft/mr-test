USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prCDCGet_dbo_PDIVendors_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create procedure [dbo].[prCDCGet_dbo_PDIVendors_PRESYNC_20150329]
as
Begin
	
	declare @from_lsn binary(10)
	declare @to_lsn binary(10)
	exec DataTrue_Main.dbo.prGetMinLSN_TableName 'dbo_PDIVendors',@from_lsn output
	exec DataTrue_Main.dbo.prGetMaxLSN @to_lsn output--sys.fn_cdc_get_max_lsn();
	select * from  [cdc].[fn_cdc_get_net_changes_dbo_PDIVendors](@from_lsn,@to_lsn,'all')
	
End
GO
