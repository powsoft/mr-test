USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_GetInventoryPerpetualView]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_GetInventoryPerpetualView]
@chainid int=null
as

if @chainid is null
	select * from InventoryPerpetual
else
	select * from InventoryPerpetual
	where ChainID = @chainid
return
GO
