USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[ZNU_prArchiveInventoryPerpetual]    Script Date: 06/25/2015 18:26:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[ZNU_prArchiveInventoryPerpetual]
as

--waitfor delay '0:0:5'

insert into DataTrue_Archive..InventoryPerpetual select * from cdc.dbo_InventoryPerpetual_CT
return
GO
