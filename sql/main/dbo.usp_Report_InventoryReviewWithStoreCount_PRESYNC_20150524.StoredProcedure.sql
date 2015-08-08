USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_InventoryReviewWithStoreCount_PRESYNC_20150524]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_Report_InventoryReviewWithStoreCount_PRESYNC_20150524]
-- exec usp_Report_InventoryReviewWithStoreCount '40393','2','All','','-1','','30','1900-01-01','1900-01-01'
@chainID varchar(20),
@PersonID int,
@Banner varchar(50),
@ProductUPC varchar(20),
@SupplierId varchar(10),
@StoreId varchar(10),
@LastxDays int,
@StartDate varchar(20),
@EndDate varchar(20)
as

Begin

Declare @sqlQuery varchar(4000)
   
    begin try
        drop table #tmp1
        drop table #tmp2
    end try
    begin catch
    end catch
--set @LastxDays = 10

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
                where s. SaleDateTime >= case when s.supplierid = 41440 then '6/1/2012' when @LastxDays>0 then  GETDATE()-@LastxDays else @StartDate end
                and t.TransactionTypeName like '%deliver%'

                group by s. StoreID,s.SupplierID,s.ProductID) D

            full outer join
               
            --Pickups
       
            (select s. StoreID,s.SupplierID,s.ProductID,- sum(s.Qty ) as CreditQnt,
                    MIN(s.SaleDateTime) as PFirstActivityDate,
                    (convert(integer,GETDATE()-MIN(s.SaleDateTime)))/7 as PWeeksSinceFirstActivity

                    from DataTrue_Report.dbo.StoreTransactions S
                    inner join
                    TransactionTypes t on t.TransactionTypeID =s.TransactionTypeID

                    where s. SaleDateTime >= case when s.supplierid = 41440 then '6/1/2012' when @LastxDays>0 then  GETDATE()-@LastxDays else @StartDate end
                    and  t.TransactionTypeName like '%pickup%'
                    group by s. StoreID,s.SupplierID,s.ProductID) P on D.ProductID =p.ProductID and d.StoreID=p.StoreID and d.SupplierID=p.SupplierID) D
       
        FULL outer join

            --POS
                (select s. StoreID,s.SupplierID,s.ProductID, sum(s.Qty ) as POSQnt,
                MIN(s.SaleDateTime) as PFirstActivityDate,
                    (convert(integer,GETDATE()-MIN(s.SaleDateTime)))/7 as PWeeksSinceFirstActivity
                   
                from DataTrue_Report.dbo.StoreTransactions S
                inner join
                    TransactionTypes t on t.TransactionTypeID =s.TransactionTypeID
					where s. SaleDateTime >= case when s.supplierid = 41440 then '6/1/2012' when @LastxDays>0 then  GETDATE()-@LastxDays else @StartDate end
                    and t.TransactionTypeName like '%POS%'

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
     
    set @sqlQuery = ' SELECT SP.SupplierName as [Supplier Name], C.ChainName as [Chain Name], S.Custom1 as Banner,B.BrandName,
                     P.ProductName as [Product], cast(I.IdentifierValue as varchar) as [UPC],PD.IdentifierValue as [Supplier Product Code],
                     ''$''+  cast(cast(T.Cost as numeric(10,2)) as varchar) as Cost, 
                     cast(count(T.storeID) as varchar) as [# Stores Selling], 
                     cast(convert(integer,SUM(Weeklymovement)) as varchar) as [Weekly POS Unit Movement],
					 cast(SUM(WeeklyDeliveries) as varchar) as [Weekly Deliveries], 
					 cast(SUM(T.currentonhand) as varchar) as [Qty Available],
                     case
                        when (sum(Weeklymovement)/7)>0 then 
							cast(convert(numeric(10,0), SUM(T.currentonhand)/(sum(Weeklymovement)/7)) as varchar)
                        else 
							cast(SUM(T.currentonhand) as varchar)
                     end   
                     as [Days on Hand],
                     case
                        when (sum(T.currentonhand) * T.Cost) >0 then
                             cast(convert(numeric(10,2),((sum(Weeklymovement) * T.Cost)/(sum(T.currentonhand) * T.Cost))) as varchar)
                        else
                            ''0''
                     end as [Inventory Turns],
                     cast(convert(numeric(10,0), sum([Weeklymovement]) / 7 * 365) as varchar) as [Annual Units Volume Threshold], 
					
					 case
						when sum(Weeklymovement) > 0 then
							cast(convert(numeric(10,0), abs((sum(Weeklymovement) - sum(WeeklyDeliveries)) / sum(Weeklymovement) * 100)) as varchar)
						else
							''0''
					 end as [Delta% - Deliveries Excess]
					
                     FROM #tmp2 T
                     
                     INNER JOIN Stores S on S.StoreId = T.StoreId and S.ActiveStatus = ''Active''
                     INNER JOIN Chains C on C.ChainId = S.ChainId
                     INNER JOIN Brands B on B.BrandId= T.BrandId
                     INNER JOIN datatrue_report.dbo.Suppliers SP on SP.SupplierId = T.SupplierId
                     INNER JOIN Products P on P.ProductId = T.ProductId
                     INNER JOIN ProductIdentifiers I on I.ProductID =P.ProductID
                     Left JOIN  ProductIdentifiers PD ON P.ProductID = PD.ProductID AND PD.ProductIdentifierTypeID =3 and PD.OwnerEntityId=T.SupplierId 
                     inner join SupplierBanners SB on SB.SupplierId = SP.SupplierId and SB.Status=''Active'' and SB.Banner=S.Custom1
                     LEFT JOIN StoresUniqueValues SUV on SUV.SupplierID = SP.SupplierID and SUV.StoreID=S.StoreID
                     WHERE 1=1'
	
	declare @AttValue int
	select @attvalue = AttributeID  from AttributeValues where OwnerEntityID=@PersonID and AttributeID=17
 
	if @AttValue =17
		set @sqlQuery = @sqlQuery + ' and C.ChainId in (select attributepart from dbo.fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 17))'
	else
		set @sqlQuery = @sqlQuery + ' and SP.SupplierId in (select attributepart from dbo.fnGetAttributeValueTable(' +  cast(@PersonID as varchar) + ', 9))'
	
	if(@chainID  <>'-1') 
		 set @sqlQuery = @sqlQuery + ' and C.ChainId=' + @ChainId 

	if(@Banner<>'All') 
		set @sqlQuery  = @sqlQuery + ' and s.custom1 like ''%' + @Banner + '%'''

	if(@SupplierId<>'-1') 
		set @sqlQuery = @sqlQuery + ' and SP.SupplierId =' + @SupplierId  

	if(@ProductUPC  <>'-1') 
		set @sqlQuery = @sqlQuery + ' and  I.IdentifierValue  like ''%' + @ProductUPC + '%'''
                    
    set @sqlQuery = @sqlQuery + ' GROUP BY SP.SupplierName, C.ChainName, S.Custom1, B.BrandName,P.ProductName, I.IdentifierValue, T.Cost, PD.IdentifierValue'
   
    exec(@sqlQuery);

End
GO
