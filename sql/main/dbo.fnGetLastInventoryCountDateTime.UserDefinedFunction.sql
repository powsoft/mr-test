USE [DataTrue_Main]
GO
/****** Object:  UserDefinedFunction [dbo].[fnGetLastInventoryCountDateTime]    Script Date: 06/25/2015 18:26:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[fnGetLastInventoryCountDateTime]
(
@StoreID int,
@ProductID int,
@BrandID int
/*
select dbo.fnGetLastInventoryCountDateTime(24112, 3444, 39)
*/
)
returns datetime

with execute as caller

as

begin
	declare @lastcountdatetime datetime
	
	select @lastcountdatetime = max(saledatetime)
	from storetransactions
	where StoreID = @StoreID
	and ProductID = @ProductID
	and BrandID = @BrandID
	and transactiontypeid in (10,11)
	
	return @lastcountdatetime
	
end
GO
