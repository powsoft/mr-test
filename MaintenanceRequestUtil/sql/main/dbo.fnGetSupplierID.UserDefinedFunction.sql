USE [DataTrue_Main]
GO
/****** Object:  UserDefinedFunction [dbo].[fnGetSupplierID]    Script Date: 06/25/2015 18:26:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[fnGetSupplierID]
(
@StoreID int,
@ProductID int,
@BrandID int,
@EffectiveDate datetime
--select dbo.fnGetSupplierID(24112, 3444, 39, '6/23/2011')
)
returns int

with execute as caller

as

begin
	declare @supplierid int
	
	select @supplierid = isnull(SupplierID, 0)
	from StoreSetup
	where StoreID = @StoreID
	and ProductID = @ProductID
	and BrandID = @BrandID
	and @EffectiveDate between ActiveStartDate and ActiveLastDate
	
	return @supplierid
	
end
GO
