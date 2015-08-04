USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prStore_New_StoreSetup_ProductPrices_Add]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prStore_New_StoreSetup_ProductPrices_Add]
  @chainid int,
  @storeid int,
  @activestartdate datetime,
  @activelastdate datetime
  
  as
  
  declare @rec cursor
  declare @productid int
  declare @supplierid int
  
  set @rec = cursor local fast_forward for 
  
  SELECT distinct [ProductID]
      ,[SupplierID]

  FROM [DataTrue_Main].[dbo].[StoreSetup]
  where storeid in (select storeid from stores where custom1 = 'Albertsons - SCAL')
  and ActiveLastDate > '7/1/2013'
  and StoreID <> 62345
  and supplierid <> 0


open @rec

fetch next from @rec into @productid, @supplierid

while @@FETCH_STATUS = 0
	begin
		INSERT INTO [DataTrue_Main].[dbo].[StoreSetup]
           ([ChainID]
           ,[StoreID]
           ,[ProductID]
           ,[SupplierID]
           ,[BrandID]
           ,[ActiveStartDate]
		   ,[ActiveLastDate]
           ,[LastUpdateUserID])
		values(40393 --[ChainID]
      ,62345 --[StoreID]
      ,@productid
      ,@supplierid
      ,0 --[BrandID]
      ,'6/1/2013'
      ,'12/31/2099'
      ,0) --[LastUpdateUserID]
		fetch next from @rec into @productid, @supplierid
	end
	
close @rec
deallocate @rec

return
GO
