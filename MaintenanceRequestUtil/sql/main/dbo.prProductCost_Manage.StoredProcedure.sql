USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prProductCost_Manage]    Script Date: 06/25/2015 18:26:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prProductCost_Manage]
@chainid int=0
,@storeid int=0
,@productid int=0
,@brandid int=0
,@supplierid int=0
,@productpricetypeid int=0
,@productcost money=0.00
,@coststartdate datetime='1/1/2000'
,@costenddate datetime='12/31/2100'
,@userid int
,@productRetail money=0.00

as

declare @errormessage nvarchar(4000)
declare @errorlocation nvarchar(255)
declare @errorsenderstring nvarchar(255)
declare @MyID int
set @MyID = 7609
declare @existingproductpriceid int
declare @existingstartdate datetime
declare @existingenddate datetime

begin try

if @chainid = 0
	begin
		select @chainid = chainid from stores where storeid = @storeid	
	end
	
begin transaction

select @existingproductpriceid = productpriceid
,@existingstartdate = ActiveStartDate
,@existingenddate = ActiveLastDate
from ProductPrices
where ProductPriceTypeID = @productpricetypeid
and StoreID = @storeid
and ProductID = @productid
and BrandID = @brandid
and ActiveLastDate > @coststartdate

if @@ROWCOUNT > 0
	begin
		if @existingenddate > @costenddate --need new existingrecord
			begin
				INSERT INTO [dbo].[ProductPrices]
						   ([ProductPriceTypeID]
						   ,[ProductID]
						   ,[ChainID]
						   ,[SupplierID]
						   ,[StoreID]
						   ,[BrandID]
						   ,[UnitPrice]
						   ,[UnitRetail]
						   ,[ActiveStartDate]
						   ,[ActiveLastDate]
						   ,[LastUpdateUserID])	
				select [ProductPriceTypeID]
						   ,[ProductID]
						   ,[ChainID]
						   ,[SupplierID]
						   ,[StoreID]
						   ,[BrandID]
						   ,[UnitPrice]
						   ,[UnitRetail]
						   ,DATEADD(day, 1, @costenddate)
						   ,[ActiveLastDate]
						   ,@userid
					from ProductPrices
					where ProductPriceID = @existingproductpriceid				
			end
		update ProductPrices set ActiveLastDate = DATEADD(day, -1, @coststartdate)
		where ProductPriceID = @existingproductpriceid
	end

--if @productpricetypeid = 4 or @productpricetypeid = 5
--	begin
		INSERT INTO [dbo].[ProductPrices]
				   ([ProductPriceTypeID]
				   ,[ProductID]
				   ,[ChainID]
				   ,[SupplierID]
				   ,[StoreID]
				   ,[BrandID]
				   ,[UnitPrice]
				   ,[UnitRetail]
				   ,[ActiveStartDate]
				   ,[ActiveLastDate]
				   ,[LastUpdateUserID])
			 VALUES
				   (@productpricetypeid
				   ,@productid
				   ,@chainid
				   ,@supplierid
				   ,@storeid
				   ,@brandid
				   ,@productcost
				   ,@productRetail
				   ,@coststartdate
				   ,@costenddate
				   ,@userid)	
--	end	

commit transaction
	
end try
	
begin catch
		rollback transaction
		
		set @errormessage = error_message()
		set @errorlocation = 'PROCESSING ERROR IN - ' + ERROR_PROCEDURE()
		set @errorsenderstring = ERROR_PROCEDURE()
		
		exec dbo.prLogExceptionAndNotifySupport
		1 --1 = System Process Error; 2 = EDI Data Issue; 3 = Cost issue
		,@errorlocation
		,@errormessage
		,@errorsenderstring
		,@MyID
		
end catch

return
GO
