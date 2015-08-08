USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_InventoryReviewWithStoreCount]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_InventoryReviewWithStoreCount]

@ChainId varchar(10),
@SupplierId varchar(10),
@Custom1 varchar(255),
@BrandId varchar(50),
@ProductIdentifierType int,
@ProductIdentifierValue varchar(50),
@ByStoreCount int,
@Cost varchar(10),
@ExcludeZeroMovement int,
@ExcludeZeroDeliveries int,
@OtherOption int,
@Others varchar(50),
@Delta int,
@LastxDays int
as

Begin

Declare @sqlQuery varchar(4000)
   
    begin try
        drop table #tmp1
        drop table #tmp2
        drop table [@tmp3]
    end try
    begin catch
    end catch

select isnull(d.storeid,po.StoreID) as StoreID,
            ISNULL(d.productid, po.productid) as ProductID,
            ISNULL(d.supplierid,po.supplierid) as SupplierID,
            isnull(D.Deliveries ,0) as Deliveries,
            isnull(D.Credits  ,0) as Credits,
            ISNULL(d.NetDeliveries ,0) as NetDeliveries,
            isnull(POSQnt ,0) as POS,
            ISNULL(d.FirstActivityDate,po.pFirstActivityDate) as FirstActivityDate,
            ISNULL(d.WeeksSinceFirstActivity,po.pWeeksSinceFirstActivity) as WeeksSinceFirstActivity,
            isnull(POSQnt ,0)/ISNULL(d.WeeksSinceFirstActivity,po.pWeeksSinceFirstActivity) as WeeklyMovement,
            isnull(d.netdeliveries ,0)/ISNULL(d.WeeksSinceFirstActivity,po.pWeeksSinceFirstActivity) as WeeklyDelivery
   
    into #tmp1           
   
        from
            --Deliveries       
            (select isnull(d.storeid,p.StoreID) as StoreID, ISNULL(d.productid, p.productid) as ProductID,
            ISNULL(d.supplierid,p.supplierid) as SupplierID,
            isnull(D.Deliveryqnt,0) as Deliveries,
            isnull(p.CreditQnt ,0) as Credits,
            ISNULL(isnull(D.Deliveryqnt,0)+isnull(p.CreditQnt ,0),0) as NetDeliveries,
            ISNULL(d.FirstActivityDate,p.pFirstActivityDate) as FirstActivityDate,
            ISNULL(d.WeeksSinceFirstActivity,p.pWeeksSinceFirstActivity) as WeeksSinceFirstActivity
           
            from
           
                (select s. StoreID,s.SupplierID,s.ProductID, sum(s.Qty ) as DeliveryQnt,
                MIN(s.SaleDateTime) as FirstActivityDate, (convert(integer,GETDATE()-MIN(s.SaleDateTime)))/7 as WeeksSinceFirstActivity

                from DataTrue_Report.dbo.StoreTransactions S
                    inner join
                    TransactionTypes t on t.TransactionTypeID =s.TransactionTypeID
                where s. SaleDateTime >= case when s.supplierid = 41440 then '6/1/2012' else GETDATE()-@LastxDays end  and t.TransactionTypeName like '%deliver%'

                group by s. StoreID,s.SupplierID,s.ProductID) D

            full outer join
               
            --Pickups
       
            (select s. StoreID,s.SupplierID,s.ProductID,- sum(s.Qty ) as CreditQnt,
                    MIN(s.SaleDateTime) as PFirstActivityDate,
                    (convert(integer,GETDATE()-MIN(s.SaleDateTime)))/7 as PWeeksSinceFirstActivity

                    from DataTrue_Report.dbo.StoreTransactions S
                    inner join
                    TransactionTypes t on t.TransactionTypeID =s.TransactionTypeID

                    where s. SaleDateTime >= case when s.supplierid = 41440 then '6/1/2012' else GETDATE()-@LastxDays end  and t.TransactionTypeName like '%pickup%'
                    group by s. StoreID,s.SupplierID,s.ProductID) P on D.ProductID =p.ProductID and d.StoreID=p.StoreID and d.SupplierID=p.SupplierID) D
       
        FULL outer join

            --POS
                (select s. StoreID,s.SupplierID,s.ProductID, sum(s.Qty ) as POSQnt,
                MIN(s.SaleDateTime) as PFirstActivityDate,
                    (convert(integer,GETDATE()-MIN(s.SaleDateTime)))/7 as PWeeksSinceFirstActivity
                   
                from DataTrue_Report.dbo.StoreTransactions S
                inner join
                    TransactionTypes t on t.TransactionTypeID =s.TransactionTypeID

                    where s. SaleDateTime >= case when s.supplierid = 41440 then '6/1/2012' else GETDATE()-@LastxDays end and t.TransactionTypeName like '%POS%'
                    --where s. SaleDateTime >=GETDATE()-@LastxDays and t.TransactionTypeName like '%POS%'

                    group by s. StoreID,s.SupplierID,s.ProductID having SUM(s.qty)<>0) Po on po.ProductID=d.ProductID and po.StoreID =d.StoreID and po.SupplierID =d.SupplierID
   
    where ISNULL(d.WeeksSinceFirstActivity,po.pWeeksSinceFirstActivity)<>0               


--ADD Invenotry
    select 
            isnull(t.storeid,i.StoreID) as StoreID,
            isnull(i.BrandID,0) as BrandID,
            ISNULL(t.productid, i.productid) as ProductID,
            ISNULL(t.supplierid,0) as SupplierID,
            isnull(t.Deliveries ,0) as Deliveries,
            isnull(t.Credits  ,0) as Credits,
            ISNULL(t.NetDeliveries ,0) as NetDeliveries,
            isnull(t.POS ,0) as POS,
            isnull(i.Cost,0) as Cost,
            ISNULL(t.FirstActivityDate,null) as FirstActivityDate,
            ISNULL(t.WeeksSinceFirstActivity,null) as WeeksSinceFirstActivity,
            isnull(convert(numeric(10,2),WeeklyMovement),0) as WeeklyMovement,
            isnull(WeeklyDelivery, 0 ) as WeeklyDeliveries,
            isnull(I.CurrentOnHandQty,0) as CurrentOnHand

    into #tmp2
    from #tmp1 T

    full outer join
        InventoryPerpetual  I on i.StoreID =t.StoreID and i.ProductID=t.ProductID
       
    --Group by Banners
   
    --IMPORTANT:
    -- Please don't change the name of [Qty Available] and [Annual Volume Threshold] fields.
    -- These column names are hard coded on the page to show the totals
    -- Also not to change the order/seq. of [UPC], [Cost], and [# Stores Selling] columns.
   
    begin try
        drop table [@tmp3]
    end try
    begin catch
    end catch
    
    set @sqlQuery = 'SELECT SP.SupplierName as [Supplier Name], C.ChainName as [Chain Name], S.Custom1 as Banner,
                     B.BrandName as [Brand Name], P.ProductName as [Product], I.IdentifierValue as [UPC], PD.IdentifierValue as [Vendor Item Number],
                     cast(T.Cost as numeric(10,2)) as Cost,'
                     
    if(@ByStoreCount=1)                     
        set @sqlQuery = @sqlQuery + ' count(T.storeID) as [# Stores Selling], '
    else
        set @sqlQuery = @sqlQuery + ' S.StoreIdentifier as [Store Number], '
   
    set @sqlQuery = @sqlQuery + ' convert(integer,SUM(Weeklymovement)) as [Weekly POS Unit Movement],
                    SUM(WeeklyDeliveries) as [Weekly Deliveries],
                    SUM(T.currentonhand) as [Qty Available],
                    case
                        when (sum(Weeklymovement)/7)>0 then convert(numeric(10,0), SUM(T.currentonhand)/(sum(Weeklymovement)/7))
                        else SUM(T.currentonhand)
                    end   
                    as [Days on Hand],
                    case
                        when (sum(T.currentonhand) * T.Cost) >0 then
                             convert(numeric(10,2),((sum(Weeklymovement) * T.Cost)/(sum(T.currentonhand) * T.Cost)))
                        else
                            0
                    end as [Inventory Turns (Per Week)],
                    convert(numeric(10,0), sum([Weeklymovement]) / 7 * 365) as [Annual Units Volume Threshold],
					
					case
						when sum(Weeklymovement) > 0 then
							convert(numeric(10,0), abs((sum(Weeklymovement) - sum(WeeklyDeliveries)) / sum(Weeklymovement) * 100))
						else
							0
					end as [Delta% - Deliveries Excess]
					
					into [@tmp3]
                    
                    FROM #tmp2 T
                    INNER JOIN Stores S on S.StoreId = T.StoreId and S.ActiveStatus = ''Active''
                    INNER JOIN Chains C on C.ChainId = S.ChainId
                    INNER JOIN Brands B on B.BrandId= T.BrandId
                    INNER JOIN Suppliers SP on SP.SupplierId = T.SupplierId
                    INNER JOIN Products P on P.ProductId = T.ProductId
                    INNER JOIN ProductIdentifiers I on I.ProductID =P.ProductID AND I.ProductIdentifierTypeID in (2,8)
					Left JOIN  ProductIdentifiers PD ON P.ProductID = PD.ProductID AND PD.ProductIdentifierTypeID =3 and PD.OwnerEntityId=SP.SupplierId
                    Inner join SupplierBanners SB on SB.SupplierId = SP.SupplierId and SB.Status=''Active'' and SB.Banner=S.Custom1
                    LEFT JOIN StoresUniqueValues SUV on SUV.SupplierID = SP.SupplierID and SUV.StoreID=S.StoreID
                    left JOIN Warehouses WH ON WH.ChainID=C.ChainID and WH.WarehouseId=SUV.DistributionCenter
                    WHERE 1=1'
                   
    if(@SupplierId<>'-1')
        set @sqlQuery = @sqlQuery + ' and SP.SupplierId =' + @SupplierId
    else
        set @sqlQuery = @sqlQuery + ' and SP.SupplierId <> 0 '
       
   
    if(@ChainId<>'-1')
        set @sqlQuery = @sqlQuery + ' and C.ChainId=' + @ChainId

    if(@BrandId<>'')
        set @sqlQuery = @sqlQuery + ' and B.BrandName= ''' + @BrandId + ''''

    if(@custom1='')
        set @sqlQuery = @sqlQuery + ' and S.custom1 is Null'

    else if(@custom1<>'-1')
        set @sqlQuery = @sqlQuery + ' and S.custom1=''' + @custom1 + ''''

    if(@ProductIdentifierValue<>'')
	begin
		
		-- 2 = UPC, 3 = Product Name , 7 = Vendor Item Number
		if (@ProductIdentifierType=2)
			 set @sqlQuery = @sqlQuery + ' and I.IdentifierValue like ''%' + @ProductIdentifierValue + '%'''
	         
		else if (@ProductIdentifierType=3)
			set @sqlQuery = @sqlQuery + ' and P.ProductName like ''%' + @ProductIdentifierValue + '%'''
			
		else if (@ProductIdentifierType=7)
			 set @sqlQuery = @sqlQuery + ' and PD.IdentifierValue like ''%' + @ProductIdentifierValue + '%'''
	end

    if(@Cost<>'0')
        set @sqlQuery = @sqlQuery + ' and  T.Cost ='  + @Cost
   
    if(@Others<>'')
    begin
        -- 1 = Distribution Center, 2 = Regional Manager, 3 = Sales Representative
        -- 4 = Supplier Account No, 5 = Driver Name, 6 = Route No
                             
        if (@OtherOption=1)
			set @sqlQuery = @sqlQuery + ' and WH.WarehouseName like ''%' + @Others + '%'''
		else if (@OtherOption=2)
			set @sqlQuery = @sqlQuery + ' and SUV.RegionalMgr like ''%' + @Others + '%'''
		else if (@OtherOption=3)
			set @sqlQuery = @sqlQuery + ' and SUV.SalesRep like ''%' + @Others + '%'''
		else if (@OtherOption=4)
			set @sqlQuery = @sqlQuery + ' and SUV.SupplierAccountNumber like ''%' + @Others + '%'''
		else if (@OtherOption=5)
			set @sqlQuery = @sqlQuery + ' and SUV.DriverName like ''%' + @Others + '%'''
		else if (@OtherOption=6)
			set @sqlQuery = @sqlQuery + ' and SUV.RouteNumber like ''%' + @Others + '%'''

    end
       
    set @sqlQuery = @sqlQuery + ' GROUP BY SP.SupplierName, C.ChainName, S.Custom1, B.BrandName,
                                  P.ProductName, I.IdentifierValue,PD.IdentifierValue, T.Cost'
    if(@ByStoreCount=0)
        set @sqlQuery = @sqlQuery + ', S.StoreIdentifier ' 
   
    if(@ExcludeZeroMovement=1 and  @ExcludeZeroDeliveries=1)
        set @sqlQuery = @sqlQuery + ' having  SUM(Weeklymovement) <> 0 or  SUM(WeeklyDeliveries) <> 0 '
   
    else if(@ExcludeZeroDeliveries=1)
        set @sqlQuery = @sqlQuery + ' having  SUM(WeeklyDeliveries) <> 0 '
   
    else if(@ExcludeZeroMovement=1)
        set @sqlQuery = @sqlQuery + ' having  SUM(Weeklymovement) <> 0 '
   
    set @sqlQuery = @sqlQuery + ' order by SP.SupplierName , C.ChainName, S.Custom1, 14 desc '
   
    execute(@sqlQuery);
    
    select * from [@tmp3] where [Delta% - Deliveries Excess] > @Delta   order by 1,2,3, 14 desc
	
End
GO
