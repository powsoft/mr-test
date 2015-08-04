USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prMR_PRODUCTPRICES_FIX_2014]    Script Date: 06/25/2015 18:26:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prMR_PRODUCTPRICES_FIX_2014]
as

declare @rec cursor
DECLARE @badrecids varchar(max)=''
DECLARE @ActivestartDate DATETIME
DECLARE @endDate DATETIME
DECLARE @startDate DATETIME
DECLARE @ActiveLastDate DATETIME
DECLARE @chainid int
DECLARE @SupplierID int
DECLARE @Storeid int
DECLARE @productid int

DECLARE @productpriceid int
DECLARE @Subject VARCHAR(MAX)=''

declare @rec1 cursor
 
 IF EXISTS (SELECT 1 
                  FROM INFORMATION_SCHEMA.TABLES 
                  WHERE TABLE_TYPE='BASE TABLE' 
                  AND TABLE_NAME='ZZtemp_MRS_set_no_dup') 
                  drop table ZZtemp_MRS_set_no_dup                            
 
begin 


select distinct storeid,productid,chainid,supplierid into ZZtemp_MRS_set_no_dup
			from MaintenanceRequests m
			 inner join MaintenanceRequestStores s
on m.MaintenanceRequestID=s.MaintenanceRequestID
where  (len(rtrim(ltrim(isnull(Bipad,''))))>1 or PDIParticipant=0)
--and PDIParticipant=0



set @rec1 = CURSOR local fast_forward FOR

	select  p.ProductPriceID,p.storeid,p.productid,p.chainid,p.supplierid,p.activestartdate,p.ActiveLastDate from 
			ProductPrices p
			inner join 
			(
			select  p.storeid,p.productid,p.chainid,p.supplierid,unitprice,cast(activestartdate as date) activestartdate
			from ZZtemp_MRS_set_no_dup z
			inner join productprices p
			on p.supplierid=z.supplierid
			and p.storeid=z.StoreID
			and p.productid=z.productid
			and ProductPriceTypeID=3
			except
			select  distinct s.storeid,m.productid,m.chainid,m.supplierid,m.cost,cast(m.startdatetime as date)
			from MaintenanceRequests m
			inner join MaintenanceRequestStores s
			on s.MaintenanceRequestID=m.MaintenanceRequestID
			inner join ZZtemp_MRS_set_no_dup z
			on m.supplierid=z.supplierid
			and s.storeid=z.StoreID
			and m.productid=z.productid
			and m.ChainID=z.chainid
			and RequestTypeID in (1,2,15))a
		
		on     a.supplierid=p.supplierid
			and a.storeid=p.StoreID
			and a.productid=p.productid
			and a.ChainID=p.chainid
			and cast(a.activestartdate as date)=cast(p.ActiveStartDate as date)
			and a.UnitPrice=p.UnitPrice
			
			order by p.storeid,p.productid  
			
			 open @rec1 

  fetch next from @rec1 into @productpriceid,@storeid,@productid,@chainid,@supplierid,@activestartdate,@ActiveLastDate

    while @@FETCH_STATUS = 0
	begin
	select 	@startdate = startdatetime
	from MaintenanceRequests m
	inner join MaintenanceRequestStores s
	on m.MaintenanceRequestID=s.MaintenanceRequestID
	and m.productid=@productid
	and m.SupplierID=@supplierid
	and m.ChainID=@chainid
	and s.StoreID=@storeid
	 and m.MaintenanceRequestID =(select min(m.MaintenanceRequestID)
	 	from MaintenanceRequests m
	inner join MaintenanceRequestStores s
	on m.MaintenanceRequestID=s.MaintenanceRequestID 
	and m.productid=@productid
	and m.SupplierID=@supplierid
	and m.ChainID=@chainid
	and s.StoreID=@storeid)
	
	if @startDate<=@ActiveLastDate
	--set @ActiveLastDate=@startDate-1
	update ProductPrices set ActiveLastDate=@startDate-1
	where 	productpriceid=@productpriceid
	--productid=@productid
	--and SupplierID=@supplierid
	--and ChainID=@chainid
	--and StoreID=@storeid
	--and UnitPrice=@unitprice
	--and ActiveLastDate=@ActiveLastDate
	--and ActiveStartDate=@ActivestartDate
	--and ProductPriceTypeID=3

	
		fetch next from @rec1 into @productpriceid,@storeid,@productid,@chainid,@supplierid,@activestartdate,@ActiveLastDate
	end
	
close @rec1
deallocate @rec1
			
  drop table ZZtemp_MRS_set_no_dup

return
end
GO
