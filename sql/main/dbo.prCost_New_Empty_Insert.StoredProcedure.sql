USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prCost_New_Empty_Insert]    Script Date: 06/25/2015 18:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[prCost_New_Empty_Insert]
@StoreID int,
@ProductID int,
@BrandID int,
@UpdateUserID int=null

as

declare @chainid int

select @chainid = ChainID from Stores where StoreID = @StoreID

if @UpdateUserID is null
	set @UpdateUserID = 2

--select top 100 * from addresses
insert into ProductPrices
(ChainID, StoreID, ProductID, BrandID, SupplierID, LastUpdateUserID)
values(@ChainID, @StoreID, @ProductID, @BrandID, 0, @UpdateUserID)

return
GO
