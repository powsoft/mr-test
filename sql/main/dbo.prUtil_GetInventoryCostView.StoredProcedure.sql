USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_GetInventoryCostView]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_GetInventoryCostView]
@chainid int=null
as

if @chainid is null
	select * from InventoryCost
	order by ReceivedAtThisCostDate
else
	select * from InventoryCost
	where ChainID = @chainid
	order by ReceivedAtThisCostDate

return
GO
