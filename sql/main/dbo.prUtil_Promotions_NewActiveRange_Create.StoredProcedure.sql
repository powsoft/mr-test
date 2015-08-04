USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Promotions_NewActiveRange_Create]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_Promotions_NewActiveRange_Create]
as

declare @rec cursor
declare @productpriceid int
declare @newrangestartdate date
declare @newrangeenddate date


set @rec = cursor local fast_forward for
 select ProductPriceID, NewActiveStartDateNeeded, NewActiveLastDateNeeded
 from ProductPrices
 where NewActiveStartDateNeeded is not null
 
 open @rec
 
 fetch next from @rec into 
	@productpriceid
	,@newrangestartdate
	,@newrangeenddate
	
while @@FETCH_STATUS = 0
	begin
	
		begin transaction
		
		INSERT INTO [DataTrue_Main].[dbo].[ProductPrices]
           ([ProductPriceTypeID]
           ,[ProductID]
           ,[ChainID]
           ,[StoreID]
           ,[BrandID]
           ,[SupplierID]
           ,[UnitPrice]
           ,[UnitRetail]
           ,[ActiveStartDate]
           ,[ActiveLastDate]
           ,[LastUpdateUserID]
           ,[OldStartDate]
           ,[OldEndDate])
SELECT [ProductPriceTypeID]
      ,[ProductID]
      ,[ChainID]
      ,[StoreID]
      ,[BrandID]
      ,[SupplierID]
      ,[UnitPrice]
      ,[UnitRetail]
      ,@newrangestartdate
      ,@newrangeenddate
      ,0
      ,[OldStartDate]
      ,[OldEndDate]

  FROM [DataTrue_Main].[dbo].[ProductPrices]
	where ProductPriceID = @productpriceid

/*
update [DataTrue_Main].[dbo].[ProductPrices]
	set Newactivestartdateneeded = null, Newactivelastdateneeded = null
	where ProductPriceID = @productpriceid
*/
		
		commit transaction

	 fetch next from @rec into 
		@productpriceid
		,@newrangestartdate
		,@newrangeenddate	
	end
	
close @rec
deallocate @rec

/*

select *
--update set p.Newactivestartdateneeded = null, p.Newactivelastdateneeded = null
	from [DataTrue_Main].[dbo].[ProductPrices] p
	 where NewActiveStartDateNeeded is not null

select top 1000 * from ProductPrices
order by datetimecreated desc

select * from ProductPrices
where productpricetypeid = 8
and ProductID in 
(
	select ProductId
	from ProductIdentifiers
	where identifiervalue in 
	(
	'074570082018',
	'074570082025',
	'074570082056',
	'074570651092',
	'074570651689'
	)
 )
 
 select *
 from ProductPrices
 where NewActiveStartDateNeeded is not null

*/

return
GO
