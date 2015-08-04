USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_WorldMart_TestData_Create]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_WorldMart_TestData_Create]

as


declare @recstate cursor
declare @stateabv nvarchar(10)
declare @storecount smallint
declare @storeentitytypeid smallint
declare @testchainid int
declare @newstoreid1 int
declare @newstoreid2 int
declare @newstoreid3 int
declare @clusterentitytypeid int
declare @cluster1 int = 40579
declare @cluster2 int = 40580
declare @cluster3 int = 40581
declare @cluster1name nvarchar(50) = 'SuperStore'
declare @cluster2name nvarchar(50) = 'FoodStore'
declare @cluster3name nvarchar(50) = 'CornerStore'
declare @genericcount int
declare @clusermembershiptypeid smallint = 1
declare @oldteststoreid int = 24113
declare @newspapercatid int = 5
declare @snackfoodcatid int = 47
declare @groceriescatid int = 77
declare @cat5prod1upc nvarchar(20) = '10000000051T' --USA Week
declare @cat5prod2upc nvarchar(20) = '10000000052T' --Local Times
declare @cat5prod3upc nvarchar(20) = '10000000053T' --Gossip Central
declare @cat47prod1upc nvarchar(20) = '10000000471T' --Pretzel Balls
declare @cat47prod2upc nvarchar(20) = '10000000472T' --Honey Penuts
declare @cat47prod3upc nvarchar(20) = '10000000473T' --Trail Mix
declare @cat77prod1upc nvarchar(20) = '10000000771T' --Pepperoni Pizza
declare @cat77prod2upc nvarchar(20) = '10000000772T' --Quick Rice
declare @cat77prod3upc nvarchar(20) = '10000000773T' --Whole Wheat Bread
declare @posstoreidentifier nvarchar(20)
declare @possupplieridentifier nvarchar(20)
declare @possaledate as date

set @testchainid = 7608
select @clusterentitytypeid = EntityTypeID from EntityTypes where EntityTypeName = 'Cluster'
select @storeentitytypeid = EntityTypeID from EntityTypes where EntityTypeName = 'Store'

/*
select supplierid from storetransactions where chainid = 7608
select * from suppliers where supplierid = 24115
select max(supplierid) from suppliers

--create clusters
select * from clusters where chainid = 7608


INSERT INTO [DataTrue_Main].[dbo].[SystemEntities]
		   ([EntityTypeID]
		   ,[LastUpdateUserID])
	 VALUES
		   (@clusterentitytypeid
		   ,2)
				
set @cluster1 = SCOPE_IDENTITY()

INSERT INTO [DataTrue_Main].[dbo].[Clusters]
           ([ClusterID]
           ,[ChainID]
           ,[ClusterName]
           ,[ClusterDescription]
           ,[LastUpdateUserID])
     VALUES
           (@cluster1
           ,@testchainid
           ,@cluster1name
           ,'Super Retail Center'
           ,2)
           
INSERT INTO [DataTrue_Main].[dbo].[SystemEntities]
		   ([EntityTypeID]
		   ,[LastUpdateUserID])
	 VALUES
		   (@clusterentitytypeid
		   ,2)
				
set @cluster2 = SCOPE_IDENTITY()

INSERT INTO [DataTrue_Main].[dbo].[Clusters]
           ([ClusterID]
           ,[ChainID]
           ,[ClusterName]
           ,[ClusterDescription]
           ,[LastUpdateUserID])
     VALUES
           (@cluster2
           ,@testchainid
           ,@cluster2name
           ,'Food Retail Center'
           ,2)

INSERT INTO [DataTrue_Main].[dbo].[SystemEntities]
		   ([EntityTypeID]
		   ,[LastUpdateUserID])
	 VALUES
		   (@clusterentitytypeid
		   ,2)
				
set @cluster3 = SCOPE_IDENTITY()

INSERT INTO [DataTrue_Main].[dbo].[Clusters]
           ([ClusterID]
           ,[ChainID]
           ,[ClusterName]
           ,[ClusterDescription]
           ,[LastUpdateUserID])
     VALUES
           (@cluster3
           ,@testchainid
           ,@cluster3name
           ,'Corner Convenience Store'
           ,2)
select *
from stores s
inner join Addresses a
on StoreID = OwnerEntityID
where s.ChainID = 7608

select *
from stores s
inner join Memberships m
on s.StoreID = MemberEntityID
inner join Clusters c
on OrganizationEntityID = ClusterID
where s.ChainID = 7608

--*******************************Three Stores Per State********************************************

           
set @recstate = CURSOR local fast_forward FOR
	select Abreviation 
	from Import.dbo.USStates
	where Abreviation <> 'AK' 
	order by Abreviation
	
open @recstate

fetch next from @recstate into @stateabv

while @@FETCH_STATUS = 0
	begin
--**********************store 1************************************				
			INSERT INTO [DataTrue_Main].[dbo].[SystemEntities]
					   ([EntityTypeID]
					   ,[LastUpdateUserID])
				 VALUES
					   (@storeentitytypeid
					   ,2)

			set @newstoreid1 = SCOPE_IDENTITY()

			INSERT INTO [DataTrue_Main].[dbo].[Stores]
					   ([StoreID]
					   ,[ChainID]
					   ,[StoreName]
					   ,[StoreIdentifier]
					   ,[ActiveFromDate]
					   ,[ActiveLastDate]
					   ,[LastUpdateUserID])
				 VALUES
					   (@newstoreid1
					   ,@testchainid
					   ,'WorldMart ' + CAST(@newstoreid1 as nvarchar)
					   ,CAST(@newstoreid1 as nvarchar)
					   ,'1/1/2009'
					   ,'12/31/2025'
					   ,2)

			INSERT INTO [DataTrue_Main].[dbo].[Memberships]
					   ([MembershipTypeID]
					   ,[OrganizationEntityID]
					   ,[MemberEntityID]
					   ,[ChainID]
					   ,[LastUpdateUserID])
				 VALUES
					   (@clusermembershiptypeid
					   ,@cluster1
					   ,@newstoreid1
					   ,@testchainid
					   ,2)

			INSERT INTO [DataTrue_Main].[dbo].[Addresses]
					   ([OwnerEntityID]
					   ,[AddressDescription]
					   ,[Address1]
					   ,[City]
					   ,[State]
					   ,[LastUpdateUserID])
				 VALUES
					   (@newstoreid1
					   ,'WorldMart ' + CAST(@newstoreid1 as nvarchar)
					   ,CAST(@newstoreid1 as nvarchar) + ' WorldMart Drive'
					   ,'One Stop'
					   ,@stateabv
					   ,2)
--**********************store 2************************************				
			INSERT INTO [DataTrue_Main].[dbo].[SystemEntities]
					   ([EntityTypeID]
					   ,[LastUpdateUserID])
				 VALUES
					   (@storeentitytypeid
					   ,2)

			set @newstoreid2 = SCOPE_IDENTITY()

			INSERT INTO [DataTrue_Main].[dbo].[Stores]
					   ([StoreID]
					   ,[ChainID]
					   ,[StoreName]
					   ,[StoreIdentifier]
					   ,[ActiveFromDate]
					   ,[ActiveLastDate]
					   ,[LastUpdateUserID])
				 VALUES
					   (@newstoreid2
					   ,@testchainid
					   ,'WorldMart ' + CAST(@newstoreid2 as nvarchar)
					   ,CAST(@newstoreid2 as nvarchar)
					   ,'1/1/2009'
					   ,'12/31/2025'
					   ,2)

			INSERT INTO [DataTrue_Main].[dbo].[Memberships]
					   ([MembershipTypeID]
					   ,[OrganizationEntityID]
					   ,[MemberEntityID]
					   ,[ChainID]
					   ,[LastUpdateUserID])
				 VALUES
					   (@clusermembershiptypeid
					   ,@cluster2
					   ,@newstoreid2
					   ,@testchainid
					   ,2)

			INSERT INTO [DataTrue_Main].[dbo].[Addresses]
					   ([OwnerEntityID]
					   ,[AddressDescription]
					   ,[Address1]
					   ,[City]
					   ,[State]
					   ,[LastUpdateUserID])
				 VALUES
					   (@newstoreid2
					   ,'WorldMart ' + CAST(@newstoreid2 as nvarchar)
					   ,CAST(@newstoreid2 as nvarchar) + ' WorldMart Drive'
					   ,'Food Stop'
					   ,@stateabv
					   ,2)
--**********************store 3************************************				
			INSERT INTO [DataTrue_Main].[dbo].[SystemEntities]
					   ([EntityTypeID]
					   ,[LastUpdateUserID])
				 VALUES
					   (@storeentitytypeid
					   ,2)

			set @newstoreid3 = SCOPE_IDENTITY()

			INSERT INTO [DataTrue_Main].[dbo].[Stores]
					   ([StoreID]
					   ,[ChainID]
					   ,[StoreName]
					   ,[StoreIdentifier]
					   ,[ActiveFromDate]
					   ,[ActiveLastDate]
					   ,[LastUpdateUserID])
				 VALUES
					   (@newstoreid3
					   ,@testchainid
					   ,'WorldMart ' + CAST(@newstoreid3 as nvarchar)
					   ,CAST(@newstoreid3 as nvarchar)
					   ,'1/1/2009'
					   ,'12/31/2025'
					   ,2)

			INSERT INTO [DataTrue_Main].[dbo].[Memberships]
					   ([MembershipTypeID]
					   ,[OrganizationEntityID]
					   ,[MemberEntityID]
					   ,[ChainID]
					   ,[LastUpdateUserID])
				 VALUES
					   (@clusermembershiptypeid
					   ,@cluster3
					   ,@newstoreid3
					   ,@testchainid
					   ,2)

			INSERT INTO [DataTrue_Main].[dbo].[Addresses]
					   ([OwnerEntityID]
					   ,[AddressDescription]
					   ,[Address1]
					   ,[City]
					   ,[State]
					   ,[LastUpdateUserID])
				 VALUES
					   (@newstoreid3
					   ,'WorldMart ' + CAST(@newstoreid3 as nvarchar)
					   ,CAST(@newstoreid3 as nvarchar) + ' WorldMart Drive'
					   ,'Quick Stop'
					   ,@stateabv
					   ,2)

--print @stateabv
			fetch next from @recstate into @stateabv
	end
	
close @recstate
deallocate @recstate


--*******************POS Data********************************

declare @cat5prod1upc nvarchar(20) = '10000000051T' --USA Week
declare @cat5prod2upc nvarchar(20) = '10000000052T' --Local Times
declare @cat5prod3upc nvarchar(20) = '10000000053T' --Gossip Central
declare @cat47prod1upc nvarchar(20) = '10000000471T' --Pretzel Balls
declare @cat47prod2upc nvarchar(20) = '10000000472T' --Honey Penuts
declare @cat47prod3upc nvarchar(20) = '10000000473T' --Trail Mix
declare @cat77prod1upc nvarchar(20) = '10000000771T' --Pepperoni Pizza
declare @cat77prod2upc nvarchar(20) = '10000000772T' --Quick Rice
declare @cat77prod3upc nvarchar(20) = '10000000773T' --Whole Wheat Bread
declare @posstoreidentifier nvarchar(20)
declare @possupplieridentifier nvarchar(20)
declare @possaledate as date

select * 
from storetransactions_working 
where 1 = 1
--and chainidentifier  = 'WorldMart'
order by StoreTransactionID desc

declare @storerec cursor
declare @qty1 int
declare @qty2 int
declare @qty3 int
declare @qty4 int
declare @qty5 int
declare @qty6 int
declare @qty7 int
declare @qty8 int
declare @qty9 int

set @qty1 = 23
set @qty2 = 10
set @qty3 = 14
set @qty4 = 5
set @qty5 = 17
set @qty6 = 17
set @qty7 = 12
set @qty8 = 11
set @qty9 = 32

--set @possaledate = '10/1/2009'

set @storerec = CURSOR local fast_forward FOR
	select cast(storeid as nvarchar) from stores 
	where ChainID = 7608 
	and StoreID >= 40582
	--and StoreID = 40582
	order by storeid
	
open @storerec

fetch next from @storerec into @posstoreidentifier

while @@FETCH_STATUS = 0
	begin
--delete from storetransactions_working where workingstatus = 0
/*
update storetransactions set Qty = Qty + 1 where chainid = 7608
*/
		set @possaledate = '7/1/2011'
		
		while @possaledate < '11/1/2011'
			begin			
				exec prUtil_Testing_InsertTestTransaction
					 'WorldMart',
					 @posstoreidentifier,
					 'NOFILE_LOAD.TXT',
					 'PPNEWS', --@SupplierIdentifier nvarchar(50),
					 @qty1, --@Qty int,
					 @possaledate,
					 '10000000051T', --@UPC nvarchar(50),
					 0, --@ReportedCost money,
					 0, --@ReportedRetail money,
					 2, --@LastUpdateUserID int,
					 'POS' --@WorkingSource nvarchar(50)	

					
				exec prUtil_Testing_InsertTestTransaction
					 'WorldMart',
					 @posstoreidentifier,
					 'NOFILE_LOAD.TXT',
					 'PPNEWS', --@SupplierIdentifier nvarchar(50),
					 @qty2, --@Qty int,
					 @possaledate,
					 '10000000052T', --@UPC nvarchar(50),
					 0, --@ReportedCost money,
					 0, --@ReportedRetail money,
					 2, --@LastUpdateUserID int,
					 'POS' --@WorkingSource nvarchar(50)
					 
					
				exec prUtil_Testing_InsertTestTransaction
					 'WorldMart',
					 @posstoreidentifier,
					 'NOFILE_LOAD.TXT',
					 'PPNEWS', --@SupplierIdentifier nvarchar(50),
					 @qty3, --@Qty int,
					 @possaledate,
					 '10000000053T', --@UPC nvarchar(50),
					 0, --@ReportedCost money,
					 0, --@ReportedRetail money,
					 2, --@LastUpdateUserID int,
					 'POS' --@WorkingSource nvarchar(50)			 	

		---second cat
				exec prUtil_Testing_InsertTestTransaction
					 'WorldMart',
					 @posstoreidentifier,
					 'NOFILE_LOAD.TXT',
					 'SFINC', --@SupplierIdentifier nvarchar(50),
					 @qty4, --@Qty int,
					 @possaledate,
					 '10000000471T', --@UPC nvarchar(50),
					 0, --@ReportedCost money,
					 0, --@ReportedRetail money,
					 2, --@LastUpdateUserID int,
					 'POS' --@WorkingSource nvarchar(50)	

					
				exec prUtil_Testing_InsertTestTransaction
					 'WorldMart',
					 @posstoreidentifier,
					 'NOFILE_LOAD.TXT',
					 'SFINC', --@SupplierIdentifier nvarchar(50),
					 @qty5, --@Qty int,
					 @possaledate,
					 '10000000472T', --@UPC nvarchar(50),
					 0, --@ReportedCost money,
					 0, --@ReportedRetail money,
					 2, --@LastUpdateUserID int,
					 'POS' --@WorkingSource nvarchar(50)
					 
					
				exec prUtil_Testing_InsertTestTransaction
					 'WorldMart',
					 @posstoreidentifier,
					 'NOFILE_LOAD.TXT',
					 'SFINC', --@SupplierIdentifier nvarchar(50),
					 @qty6, --@Qty int,
					 @possaledate,
					 '10000000473T', --@UPC nvarchar(50),
					 0, --@ReportedCost money,
					 0, --@ReportedRetail money,
					 2, --@LastUpdateUserID int,
					 'POS' --@WorkingSource nvarchar(50)	
		--third cat
				exec prUtil_Testing_InsertTestTransaction
					 'WorldMart',
					 @posstoreidentifier,
					 'NOFILE_LOAD.TXT',
					 'QFINTRNL', --@SupplierIdentifier nvarchar(50),
					 @qty7, --@Qty int,
					 @possaledate,
					 '10000000771T', --@UPC nvarchar(50),
					 0, --@ReportedCost money,
					 0, --@ReportedRetail money,
					 2, --@LastUpdateUserID int,
					 'POS' --@WorkingSource nvarchar(50)	

					
				exec prUtil_Testing_InsertTestTransaction
					 'WorldMart',
					 @posstoreidentifier,
					 'NOFILE_LOAD.TXT',
					 'QFINTRNL', --@SupplierIdentifier nvarchar(50),
					 @qty8, --@Qty int,
					 @possaledate,
					 '10000000772T', --@UPC nvarchar(50),
					 0, --@ReportedCost money,
					 0, --@ReportedRetail money,
					 2, --@LastUpdateUserID int,
					 'POS' --@WorkingSource nvarchar(50)
					 
					
				exec prUtil_Testing_InsertTestTransaction
					 'WorldMart',
					 @posstoreidentifier,
					 'NOFILE_LOAD.TXT',
					 'QFINTRNL', --@SupplierIdentifier nvarchar(50),
					 @qty9, --@Qty int,
					 @possaledate,
					 '10000000773T', --@UPC nvarchar(50),
					 0, --@ReportedCost money,
					 0, --@ReportedRetail money,
					 2, --@LastUpdateUserID int,
					 'POS' --@WorkingSource nvarchar(50)	
					 
				set @possaledate = dateadd(day, 3, @possaledate)
			 end
		fetch next from @storerec into @posstoreidentifier
	end
	
close @storerec
deallocate @storerec



select s.SupplierID, s.SupplierIdentifier, 
w.SupplierIdentifier, w.SupplierID, w.workingstatus,
w.datetimecreated
--update w set w.SupplierID = s.SupplierID, workingstatus = 2
from StoreTransactions_Working w
inner join Suppliers s
on ltrim(rtrim(w.SupplierIdentifier)) = ltrim(rtrim(s.SupplierIdentifier))
where w.ChainID = 7608
and w.WorkingStatus = -2


*/

--INV records
select *
--update t set t.TrueCost = t.RuleCost, t.TrueRetail = t.RuleRetail, t.CostMisMatch = 0, t.RetailMisMatch = 0
from storetransactions t
where ChainID = 7608
and TransactionTypeID = 11
and TrueCost is null

declare @storerec cursor
declare @invstoreidentifier nvarchar(50)
declare @invupc nvarchar(50)
declare @invsupplieridentifier nvarchar(50)
declare @invqty nvarchar(50)


set @storerec = CURSOR local fast_forward FOR
	select StoreIdentifier, UPC, SupplierIdentifier, SUM(Qty) as Qty
	from StoreTransactions_working t
	where SaleDateTime < '10/11/2009'
	group by StoreIdentifier, UPC, SupplierIdentifier
	order by StoreIdentifier, UPC, SupplierIdentifier
	
open @storerec

fetch next from @storerec into @invstoreidentifier, @invupc, @invsupplieridentifier, @invqty

while @@FETCH_STATUS = 0
	begin
		
				exec prUtil_Testing_InsertTestTransaction
					 'WorldMart',
					 @invstoreidentifier,
					 'INV_NOFILE_LOAD.TXT',
					 @invsupplieridentifier,
					 @invqty,
					 '9/1/2009',
					 @invupc,
					 0, --@ReportedCost money,
					 0, --@ReportedRetail money,
					 2, --@LastUpdateUserID int,
					 'INV' --@WorkingSource nvarchar(50)
					 	
			fetch next from @storerec into @invstoreidentifier, @invupc, @invsupplieridentifier, @invqty
	end
	
close @storerec
deallocate @storerec

--select cast(3 * .70 as int)

	select *
	--update t set Qty = cast(Qty / .54 as int)
	from datatrue_report.dbo.storetransactions t
	where saledatetime between '1/1/2009' and '12/31/2009'
	and storeid in
		(
		select storeid
		from stores s
		inner join Addresses a
		on s.StoreID = a.OwnerEntityID
		where s.ChainID = 7608
		and a.State = 'AK'
		)
		
			select *
	--update t set Qty = cast(Qty / .69 as int)
	from datatrue_report.dbo.storetransactions t
	where saledatetime between '1/1/2010' and '12/31/2010'
	and storeid in
		(
		select storeid
		from stores s
		inner join Addresses a
		on s.StoreID = a.OwnerEntityID
		where s.ChainID = 7608
		and a.State = 'AK'
		)

			select *
	--update t set Qty = cast(Qty * .80 as int)
	from datatrue_report.dbo.storetransactions t
	where saledatetime between '1/1/2011' and '12/31/2011'
	and storeid in
		(
		select storeid
		from stores s
		inner join Addresses a
		on s.StoreID = a.OwnerEntityID
		where s.ChainID = 7608
		and a.State = 'AK'
		)

declare @recstatediff cursor
declare @storeid int
declare @state nvarchar(10)
declare @percentadd float

set @percentadd = .02

set @recstatediff = CURSOR local fast_forward FOR
	select distinct a.[State]
	from stores s
	inner join Addresses a
	on s.StoreID = a.OwnerEntityID
	where s.ChainID = 7608
	and a.State <> 'AK'
	order by a.State
	
open @recstatediff

fetch next from @recstatediff into @state

while @@FETCH_STATUS = 0
	begin
	--select *
	set @percentadd = @percentadd + .02
	
	update t set Qty = cast(Qty * (.50 + @percentadd) as int)
	from datatrue_report.dbo.storetransactions t
	where saledatetime between '1/1/2009' and '12/31/2009'
	and storeid in
		(
		select storeid
		from stores s
		inner join Addresses a
		on s.StoreID = a.OwnerEntityID
		where s.ChainID = 7608
		and a.State = @state
		)
		

	update t set Qty = cast(Qty * (.65 + @percentadd) as int)
	from datatrue_report.dbo.storetransactions t
	where saledatetime between '1/1/2010' and '12/31/2010'
	and storeid in
		(
		select storeid
		from stores s
		inner join Addresses a
		on s.StoreID = a.OwnerEntityID
		where s.ChainID = 7608
		and a.State = @state
		)


	update t set Qty = cast(Qty * (.75 + @percentadd) as int)
	from datatrue_report.dbo.storetransactions t
	where saledatetime between '1/1/2011' and '12/31/2011'
	and storeid in
		(
		select storeid
		from stores s
		inner join Addresses a
		on s.StoreID = a.OwnerEntityID
		where s.ChainID = 7608
		and a.State = @state
		)
	fetch next from @recstatediff into @state

  end
  
close @recstatediff
deallocate @recstatediff

select * into Import..StoreTransactions_beforetestsyncbacktoMain from StoreTransactions
select m.qty, r.qty, m.storetransactionid, m.StoreID, r.StoreID, m.ProductID, r.ProductID, m.SaleDateTime, r.SaleDateTime
--update m set m.qty = m.qty
from StoreTransactions m
inner join Datatrue_Report.dbo.StoreTransactions r
on m.StoreTransactionID = r.StoreTransactionID
and r.ChainID = 7608
and r.ProductID > 7000
order by r.SaleDateTime desc


--StoreSetup Update
select *
from storesetup
where ChainID = 7608
and productid > 6000

INSERT INTO [DataTrue_Main].[dbo].[StoreSetup]
           ([ChainID]
           ,[StoreID]
           ,[ProductID]
           ,[SupplierID]
           ,[BrandID]
           ,[InventoryCostMethod]
           ,[ActiveStartDate]
           ,[ActiveLastDate]
           ,[LastUpdateUserID])
 
	select distinct chainid, storeid, ProductId, supplierid, brandid, 'FIFO', '1/1/2000', '12/31/2025', 2
	from StoreTransactions
	where ProductID > 6000
	and ChainID = 7608


declare @recdeliveries cursor
declare @suptransactionid bigint
declare @supchainid int
declare @supstoreid int
declare @supsupplierid int
declare @suptransqty int
declare @supsaledatetime datetime
declare @supproductid int
declare @supbrandid int
declare @truecost money
declare @trueretail money
declare @supdeliveryqty int
declare @suppickupqty int
declare @suppickupdatetime datetime
declare @supupc nvarchar(50)

set @recdeliveries = CURSOR local fast_forward FOR
	select storetransactionid
		,chainid
		,StoreID
		,SupplierID
		,Qty
		,SaleDateTime
		,ProductID
		,BrandID
		,SetupCost
		,SetupRetail
		,UPC
	from StoreTransactions t
	where ChainID = 7608
	and TransactionTypeID = 2
	and SaleDateTime between '10/1/2011' and '10/31/2011'
	order by SaleDateTime, StoreID, productid
		
		
open @recdeliveries


fetch next from @recdeliveries into
	@suptransactionid
	,@supchainid
	,@supstoreid
	,@supsupplierid
	,@suptransqty
	,@supsaledatetime
	,@supproductid
	,@supbrandid
	,@truecost
	,@trueretail
	,@supupc
	
while @@FETCH_STATUS = 0
	begin
	
		--Delivery cast(qty * 1.3 as int) select cast(4 * 1.3 as int)
		set @supdeliveryqty = CAST(1.3*@suptransqty as int)
		set @suppickupqty = CAST(.15*@suptransqty as int)
		set @suppickupdatetime = dateadd(day, 1, @supSaleDateTime)
		
		exec prUtil_Testing_InsertTestTransaction_WithIDs
			 @supChainId,
			 @supStoreId,
			 780,
			 @supSupplierId,
			 @supdeliveryqty,
			 @supSaleDateTime,
			 @supProductID,
			 @supbrandid,
			 @truecost,
			 @trueretail,
			 2,
			 'SUP-S',
			 @supupc

		if @suppickupqty > 0
			begin
				exec prUtil_Testing_InsertTestTransaction_WithIDs
					 @supChainId,
					 @supStoreId,
					 780,
					 @supSupplierId,
					 @suppickupqty,
					 @suppickupdatetime,
					 @supProductID,
					 @supbrandid,
					 @truecost,
					 @trueretail,
					 2,
					 'SUP-U',
					 @supupc
			end	
			 
		update StoreTransactions set TrueCost = RuleCost,
			TrueRetail = RuleRetail, CostMisMatch = 0, RetailMisMatch = 0
			where StoreTransactionID = @suptransactionid		 
			 		

		fetch next from @recdeliveries into
			@suptransactionid
			,@supchainid
			,@supstoreid
			,@supsupplierid
			,@suptransqty
			,@supsaledatetime
			,@supproductid
			,@supbrandid
			,@truecost
			,@trueretail
			,@supupc	
	end
	
close @recdeliveries
deallocate @recdeliveries
		
		
select *
--update w set workingstatus = 4, sourceid = 780
from StoreTransactions_Working w
where WorkingStatus = 3	
and ChainID = 7608
and WorkingSource in ('SUP-S', 'SUP-U')	

INSERT INTO [DataTrue_Main].[dbo].[StoreTransactions_Working]
           ([ChainID]
           ,[ChainIdentifier]
           ,[StoreIdentifier]
           ,[SourceIdentifier]
           ,[SupplierIdentifier]
           ,[DateTimeSourceReceived]
           ,[StoreID]
           ,[ProductID]
           ,[SupplierID]
           ,[TransactionTypeID]
           ,[ProductPriceTypeID]
           ,[BrandID]
           ,[Qty]
           ,[SetupCost]
           ,[SetupRetail]
           ,[SaleDateTime]
           ,[UPC]
           ,[ProductIdentifierType]
           ,[ProductCategoryIdentifier]
           ,[BrandIdentifier]
           ,[SupplierInvoiceNumber]
           ,[ReportedCost]
           ,[ReportedRetail]
           ,[ReportedPromotionPrice]
           ,[ReportedAllowance]
           ,[RuleCost]
           ,[RuleRetail]
           ,[CostMisMatch]
           ,[RetailMisMatch]
           ,[TrueCost]
           ,[TrueRetail]
           ,[ActualCostNetFee]
           ,[TransactionStatus]
           ,[Reversed]
           ,[ProcessingErrorDesc]
           ,[SourceID]
           ,[Comments]
           ,[InvoiceID]
           ,[DateTimeCreated]
           ,[LastUpdateUserID]
           ,[DateTimeLastUpdate]
           ,[WorkingSource]
           ,[WorkingStatus]
           ,[RecordID_EDI_852])
SELECT [ChainID]
      ,[ChainIdentifier]
      ,[StoreIdentifier]
      ,[SourceIdentifier]
      ,[SupplierIdentifier]
      ,[DateTimeSourceReceived]
      ,[StoreID]
      ,[ProductID]
      ,[SupplierID]
      ,[TransactionTypeID]
      ,[ProductPriceTypeID]
      ,[BrandID]
      ,[Qty]
      ,[SetupCost]
      ,[SetupRetail]
      ,'10/1/2011'
      ,[UPC]
      ,[ProductIdentifierType]
      ,[ProductCategoryIdentifier]
      ,[BrandIdentifier]
      ,[SupplierInvoiceNumber]
      ,[ReportedCost]
      ,[ReportedRetail]
      ,[ReportedPromotionPrice]
      ,[ReportedAllowance]
      ,[RuleCost]
      ,[RuleRetail]
      ,[CostMisMatch]
      ,[RetailMisMatch]
      ,[TrueCost]
      ,[TrueRetail]
      ,[ActualCostNetFee]
      ,[TransactionStatus]
      ,[Reversed]
      ,[ProcessingErrorDesc]
      ,[SourceID]
      ,[Comments]
      ,[InvoiceID]
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
      ,[WorkingSource]
      ,4
      ,[RecordID_EDI_852]
  FROM [DataTrue_Main].[dbo].[StoreTransactions_Working]
where saledatetime = '4/1/2011'
and transactiontypeid = 11

--what is current shrink percent
select SUM(qty) from StoreTransactions where ChainID = 7608 and TransactionTypeID = 2
select SUM(qty) from StoreTransactions where ChainID = 7608 and TransactionTypeID = 17


select w.Qty, i.SBTSales, i.CurrentOnHandQty, i.CurrentOnHandQty - CAST(i.SBTSales * .006 as int)
--select w.*
--update w set w.qty = i.CurrentOnHandQty - CAST(i.SBTSales * .006 as int) 
  FROM [DataTrue_Main].[dbo].[StoreTransactions_Working] w
  inner join InventoryPerpetual i
  on w.StoreID = i.StoreID
  and w.ProductID = i.ProductID
  and w.BrandID = i.brandid
  where SaleDateTime = '10/1/2011'
  and w.TransactionTypeID = 11
  order by i.CurrentOnHandQty - CAST(i.SBTSales * .006 as int)
  
  select *
  --update t set TrueCost = RuleCost, TrueRetail = ruleretail, ReportedCost = RuleCost, ReportedRetail = ruleretail, CostMisMatch = 0, RetailMisMatch = 0
  from [DataTrue_Main].[dbo].[StoreTransactions] t
  where SaleDateTime = '10/1/2011'
  and TransactionTypeID = 11
  
  INSERT INTO [DataTrue_Main].[dbo].[StoreTransactions]
           ([ChainID]
           ,[StoreID]
           ,[ProductID]
           ,[SupplierID]
           ,[TransactionTypeID]
           ,[ProductPriceTypeID]
           ,[BrandID]
           ,[Qty]
           ,[SetupCost]
           ,[SetupRetail]
           ,[SaleDateTime]
           ,[UPC]
           ,[SupplierInvoiceNumber]
           ,[ReportedCost]
           ,[ReportedRetail]
           ,[ReportedAllowance]
           ,[ReportedPromotionPrice]
           ,[RuleCost]
           ,[RuleRetail]
           ,[CostMisMatch]
           ,[RetailMisMatch]
           ,[TrueCost]
           ,[TrueRetail]
           ,[ActualCostNetFee]
           ,[TransactionStatus]
           ,[Reversed]
           ,[ProcessingErrorDesc]
           ,[SourceID]
           ,[Comments]
           ,[InvoiceID]
           ,[DateTimeCreated]
           ,[LastUpdateUserID]
           ,[DateTimeLastUpdate]
           ,[WorkingTransactionID]
           ,[InvoiceBatchID]
           ,[InventoryCost])
SELECT [ChainID]
      ,[StoreID]
      ,[ProductID]
      ,[SupplierID]
      ,[TransactionTypeID]
      ,[ProductPriceTypeID]
      ,[BrandID]
      ,0
      ,[SetupCost]
      ,[SetupRetail]
      ,'4/4/2010'
      ,[UPC]
      ,[SupplierInvoiceNumber]
      ,[ReportedCost]
      ,[ReportedRetail]
      ,[ReportedAllowance]
      ,[ReportedPromotionPrice]
      ,[RuleCost]
      ,[RuleRetail]
      ,[CostMisMatch]
      ,[RetailMisMatch]
      ,[TrueCost]
      ,[TrueRetail]
      ,[ActualCostNetFee]
      ,0
      ,[Reversed]
      ,[ProcessingErrorDesc]
      ,[SourceID]
      ,[Comments]
      ,[InvoiceID]
      ,[DateTimeCreated]
      ,[LastUpdateUserID]
      ,[DateTimeLastUpdate]
      ,[WorkingTransactionID]
      ,[InvoiceBatchID]
      ,[InventoryCost]
  FROM [DataTrue_Main].[dbo].[StoreTransactions]
 WHERE     (SaleDateTime = '4/3/2010')
 
 select OriginalQty, i.CurrentOnHandQty, i.CurrentOnHandQty - OriginalQty, *
 --select *
 --update t set t.Qty = i.CurrentOnHandQty - OriginalQty
 FROM [DataTrue_Main].[dbo].[StoreTransactions] t
 inner join InventoryPerpetual i
 on t.StoreID = i.StoreID
 and t.ProductID = i.ProductID
 and t.BrandID = i.BrandID
 where SaleDateTime = '4/4/2010'
 and t.ChainID = 7608
 
  
  order by i.CurrentOnHandQty - CAST(i.SBTSales * .02 as int)
  
  update [DataTrue_Main].[dbo].[StoreTransactions_Working]
set workingsource = 'INV', ReportedCost = RuleCost, ReportedRetail = ruleretail, CostMisMatch = 0, RetailMisMatch = 0
  where SaleDateTime = '4/1/2010'


  
  
return
GO
