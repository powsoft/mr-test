USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[ZNU_prUtil_CDC_Enable]    Script Date: 06/25/2015 18:26:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[ZNU_prUtil_CDC_Enable]
as

EXEC Sp_cdc_enable_table 
 @source_schema =  'dbo', 
  @source_name =  'InventoryPerpetual' ,
  @role_name =  'datatrueadmin',
  @supports_net_changes = 1
  
  return
GO
