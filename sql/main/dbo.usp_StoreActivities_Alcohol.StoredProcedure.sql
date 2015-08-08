USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_StoreActivities_Alcohol]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_StoreActivities_Alcohol]
 @ChainId varchar(5),
 @SupplierID varchar(5),
 @custom1 varchar(255),
 @ActivityType varchar(50),
 @BrandId varchar(5),
 @TransFromDate varchar(50),
 @TransToDate varchar(50),
 @ProductIdentifierType int,
 @ProductIdentifierValue varchar(50),
 @StoreIdentifierType int,
 @StoreIdentifierValue varchar(50),
 @OtherOption int,
 @Others varchar(50),
 @ShowAggregate int,
 @SupplierInvoiceNumber varchar(50),
 @CreditType varchar(20)
 
 
as
--exec [usp_StoreActivities_Alcohol] '44199','-1','Dollar General','17','-1','08/01/2012','08/30/2012',2,'','1','','1','',0,'-1',0
Begin
 Declare @sqlQuery varchar(8000)
 Declare @CostFormat varchar(10)
 
 if(@supplierID<>'-1')
	Select @CostFormat = Costformat from SupplierFormat where SupplierID = @supplierID
 else
	set @CostFormat=4
 
     if (@ActivityType='17,18,19,22,23')
        Begin
            set @sqlQuery = 'select SupplierName, ST.Custom1 as Banner, ST.StoreName as Store,
                                 ST.StoreIdentifier as [Store No],
                                '''' as [Supplier Reference No],
                                P.ProductName as Product, I.UPC, I.UPC as [Vendor Item Number], B.BrandName as Manufacturer,
                                ''Shrink'' as Type, convert(varchar(10), I.PhysicalInventoryDate, 101) as [Transaction Date], 
                                I.ShrinkUnits as Qty, cast(I.WeightedAvgCost as numeric(10, ' + @CostFormat + '))  as Cost, 
                                '''' as Promo 
             from InventorySettlementRequests I
             inner join Suppliers S on S.SupplierID=I.supplierId
             inner join Stores ST on ST.StoreID=I.StoreID and ST.ActiveStatus=''Active''
             inner join Products P on P.ProductID=I.ProductID 
             INNER JOIN ProductBrandAssignments PB on PB.ProductID=P.ProductID 
			 INNER JOIN Brands B ON PB.BrandID = B.BrandID 
             left outer join dbo.ProductIdentifiers PD on P.ProductID = PD.ProductID and PD.ProductIdentifierTypeId =3 and PD.OwnerEntityId=S.SupplierID
             inner join SupplierBanners SB on SB.SupplierId = S.SupplierId and SB.Status=''Active'' and SB.Banner=ST.Custom1 where 1=1 '
             
             if(@ChainId <>'-1')
                set @sqlQuery = @sqlQuery +  ' and ST.ChainID=' + @ChainId
         
            if(@SupplierID <>'-1')
                set @sqlQuery = @sqlQuery +  ' and I.SupplierId=' + @SupplierId
         
            if(@custom1='')
                set @sqlQuery = @sqlQuery + ' and ST.custom1 is Null'
            else if(@custom1<>'-1')
                set @sqlQuery = @sqlQuery + ' and ST.custom1=''' + @custom1 + ''''
               
            if (convert(date, @TransFromDate  ) > convert(date,'1900-01-01'))
                set @sqlQuery = @sqlQuery + ' and I.PhysicalInventoryDate  >= ''' + @TransFromDate  + ''''
         
            if(convert(date, @TransToDate ) > convert(date,'1900-01-01'))
                set @sqlQuery = @sqlQuery + ' and I.PhysicalInventoryDate  <=''' + @TransToDate  + ''''
	
			 if(@ProductIdentifierValue<>'')
			 begin

				-- 2 = UPC, 3 = Product Name 
				if (@ProductIdentifierType=2)
					 set @sqlQuery = @sqlQuery + ' and I.UPC like ''%' + @ProductIdentifierValue + '%'''
			         
				else if (@ProductIdentifierType=3)
					set @sqlQuery = @sqlQuery + ' and P.ProductName like ''%' + @ProductIdentifierValue + '%'''
					
				else if (@ProductIdentifierType=7)
					 set @sqlQuery = @sqlQuery + ' and PD.IdentifierValue like ''%' + @ProductIdentifierValue + '%'''
			 end
 
            
            if(@StoreIdentifierValue<>'')
                begin
                    -- 1 = Store Number, 2 = SBT Number, 3 = Store Name
                    if (@StoreIdentifierType=1)
                        set @sqlQuery = @sqlQuery + ' and ST.storeidentifier like ''%' + @StoreIdentifierValue + '%'''
                    else if (@StoreIdentifierType=2)
                        set @sqlQuery = @sqlQuery + ' and ST.Custom2 like ''%' + @StoreIdentifierValue + '%'''
                    else if (@StoreIdentifierType=3)
                        set @sqlQuery = @sqlQuery + ' and ST.StoreName like ''%' + @StoreIdentifierValue + '%'''
                end
               
     
            set @sqlQuery = @sqlQuery + ' Union ALL '
             
             set @sqlQuery = @sqlQuery + ' select MR.SupplierName, MR.Banner,
                                             ST.StoreName as Store,  ST.StoreIdentifier as [Store No],
                                            '''' as [Supplier Reference No],
                                            P.ProductName as Product, MR.UPC,MR.UPC as [Vendor Item Number], B.BrandName as Brand,
                                            ''Pending Shrink'' as Type, convert(varchar(10),MR.LastInventoryCountDate, 101) as [Transaction Date], 
                                            MR.ShrinkUnits as Qty, cast(MR.WeightedAvgCost as numeric(10, ' + @CostFormat + '))  as Cost, 
                                            '''' as Promo 
                                         from DataTrue_CustomResultSets.dbo.InventoryReport_New_FactTable_Active MR
                                         inner join Stores ST on ST.StoreID=MR.StoreID
                                         inner join Products P on P.ProductID=MR.ProductID
                                         INNER JOIN ProductBrandAssignments PB on PB.ProductID=P.ProductID 
										 INNER JOIN Brands B ON PB.BrandID = B.BrandID 
                                         left outer join dbo.ProductIdentifiers PD on P.ProductID = PD.ProductID and PD.ProductIdentifierTypeId =3 and PD.OwnerEntityId=MR.SupplierID
                                         inner join SupplierBanners SB on SB.SupplierId = MR.SupplierId and SB.Status=''Active'' and SB.Banner=ST.Custom1
                                         where LastInventoryCountDate > (select MAX(PhysicalInventoryDate) from InventorySettlementRequests I
                                                                            where I.supplierId=MR.SupplierID and I.StoreID=MR.StoreID
                                                                            and I.ProductID=MR.ProductID)'
           
            if(@ChainId <>'-1')
                set @sqlQuery = @sqlQuery +  ' and ST.ChainID=' + @ChainId
         
            if(@SupplierID <>'-1')
                set @sqlQuery = @sqlQuery +  ' and MR.SupplierId=' + @SupplierId
         
            if(@custom1='')
                set @sqlQuery = @sqlQuery + ' and ST.custom1 is Null'
            else if(@custom1<>'-1')
                set @sqlQuery = @sqlQuery + ' and ST.custom1=''' + @custom1 + ''''
               
            if (convert(date, @TransFromDate  ) > convert(date,'1900-01-01'))
                set @sqlQuery = @sqlQuery + ' and MR.LastInventoryCountDate  >= ''' + @TransFromDate  + ''''
         
            if(convert(date, @TransToDate ) > convert(date,'1900-01-01'))
                set @sqlQuery = @sqlQuery + ' and MR.LastInventoryCountDate  <=''' + @TransToDate  + ''''

         
            if(@ProductIdentifierValue<>'')
			 begin

				-- 2 = UPC, 3 = Product Name 
				if (@ProductIdentifierType=2)
					 set @sqlQuery = @sqlQuery + ' and MR.UPC like ''%' + @ProductIdentifierValue + '%'''
			         
				else if (@ProductIdentifierType=3)
					set @sqlQuery = @sqlQuery + ' and P.ProductName like ''%' + @ProductIdentifierValue + '%'''
				
				else if (@ProductIdentifierType=7)
					 set @sqlQuery = @sqlQuery + ' and PD.IdentifierValue like ''%' + @ProductIdentifierValue + '%'''
			 end
         
            if(@StoreIdentifierValue<>'')
                begin
                    -- 1 = Store Number, 2 = SBT Number, 3 = Store Name
                    if (@StoreIdentifierType=1)
                        set @sqlQuery = @sqlQuery + ' and ST.storeidentifier like ''%' + @StoreIdentifierValue + '%'''
                    else if (@StoreIdentifierType=2)
                        set @sqlQuery = @sqlQuery + ' and ST.Custom2 like ''%' + @StoreIdentifierValue + '%'''
                    else if (@StoreIdentifierType=3)
                        set @sqlQuery = @sqlQuery + ' and ST.StoreName like ''%' + @StoreIdentifierValue + '%'''
                end
               
                set @sqlQuery = @sqlQuery + ' Union ALL '
             
             set @sqlQuery = @sqlQuery + ' select MR.SupplierName, MR.Banner,
                                             ST.StoreName as Store,  ST.StoreIdentifier as [Store No],
                                            '''' as [Supplier Reference No],
                                            P.ProductName as Product, MR.UPC,MR.UPC as [Vendor Item Number], B.BrandName as Brand,
                                            ''Pending Shrink'' as Type, convert(varchar(10),MR.LastInventoryCountDate, 101) as [Transaction Date], 
                                            MR.ShrinkUnits as Qty, cast(MR.WeightedAvgCost as numeric(10, ' + @CostFormat + '))  as Cost, '''' as Promo
                                         from DataTrue_CustomResultSets.dbo.InventoryReport_New_FactTable_Active MR
                                         inner join Stores ST on ST.StoreID=MR.StoreID
                                         inner join Products P on P.ProductID=MR.ProductID
                                         INNER JOIN ProductBrandAssignments PB on PB.ProductID=P.ProductID 
										 INNER JOIN Brands B ON PB.BrandID = B.BrandID 
                                         left outer join dbo.ProductIdentifiers PD on P.ProductID = PD.ProductID and PD.ProductIdentifierTypeId =3 and PD.OwnerEntityId=MR.SupplierID
                                         inner join SupplierBanners SB on SB.SupplierId = MR.SupplierId and SB.Status=''Active'' and SB.Banner=ST.Custom1
                                         left join InventorySettlementRequests  I on I.supplierId=MR.SupplierID
                                         and I.StoreID=MR.StoreID and I.ProductID=MR.ProductID
                                         where I.supplierId is null '
           
            if(@ChainId <>'-1')
                set @sqlQuery = @sqlQuery +  ' and ST.ChainID=' + @ChainId
         
            if(@SupplierID <>'-1')
                set @sqlQuery = @sqlQuery +  ' and MR.SupplierId=' + @SupplierId
         
            if(@custom1='')
                set @sqlQuery = @sqlQuery + ' and ST.custom1 is Null'
            else if(@custom1<>'-1')
                set @sqlQuery = @sqlQuery + ' and ST.custom1=''' + @custom1 + ''''
               
            if (convert(date, @TransFromDate  ) > convert(date,'1900-01-01'))
                set @sqlQuery = @sqlQuery + ' and MR.LastInventoryCountDate  >= ''' + @TransFromDate  + ''''
         
            if(convert(date, @TransToDate ) > convert(date,'1900-01-01'))
                set @sqlQuery = @sqlQuery + ' and MR.LastInventoryCountDate  <=''' + @TransToDate  + ''''

         
            if(@ProductIdentifierValue<>'')
			 begin

				-- 2 = UPC, 3 = Product Name , 7= Vendor Item Number
				if (@ProductIdentifierType=2)
					 set @sqlQuery = @sqlQuery + ' and MR.UPC like ''%' + @ProductIdentifierValue + '%'''
			         
				else if (@ProductIdentifierType=3)
					set @sqlQuery = @sqlQuery + ' and P.ProductName like ''%' + @ProductIdentifierValue + '%'''
					
				else if (@ProductIdentifierType=7)
					 set @sqlQuery = @sqlQuery + ' and PD.IdentifierValue like ''%' + @ProductIdentifierValue + '%'''
			 end 
         
            if(@StoreIdentifierValue<>'')
                begin
                    -- 1 = Store Number, 2 = SBT Number, 3 = Store Name
                    if (@StoreIdentifierType=1)
                        set @sqlQuery = @sqlQuery + ' and ST.storeidentifier like ''%' + @StoreIdentifierValue + '%'''
                    else if (@StoreIdentifierType=2)
                        set @sqlQuery = @sqlQuery + ' and ST.Custom2 like ''%' + @StoreIdentifierValue + '%'''
                    else if (@StoreIdentifierType=3)
                        set @sqlQuery = @sqlQuery + ' and ST.StoreName like ''%' + @StoreIdentifierValue + '%'''
                end
        end
    else
        begin

             set @sqlQuery = 'SELECT  dbo.Suppliers.SupplierName as Supplier, '
             if (@ShowAggregate=0)
                set @sqlQuery = @sqlQuery +  'dbo.Stores.custom1 as Banner, dbo.Stores.StoreName as Store,
                                    dbo.Stores.StoreIdentifier as [Store No], S.SupplierInvoiceNumber as [Supplier Reference No],  '
             
             set @sqlQuery = @sqlQuery +  ' dbo.Brands.BrandName as Manufacturer, dbo.Products.ProductName as Product, dbo.ProductIdentifiers.IdentifierValue as UPC, 
             dbo.ProductIdentifiers.IdentifierValue as [Vendor Item Number], dbo.TransactionTypes.TransactionTypeName as Type, convert(varchar(10), S.SaleDateTime, 101) as [Transaction Date], '

             if (@ShowAggregate=1)                     
                set @sqlQuery = @sqlQuery +  ' case when dbo.TransactionTypes.transactiontypeid in (21,8,14) then -sum(S.Qty) else sum(S.Qty) end   as Qty, '
             else
                 set @sqlQuery = @sqlQuery +  ' case when TransactionTypes.transactiontypeid in (21,8,14) then  -S.Qty else S.Qty end as Qty, '
                                  
             set @sqlQuery = @sqlQuery +  ' cast(S.rulecost as numeric(10, ' + @CostFormat + '))  as Cost, S.Promoallowance as Promo '
             
             if (@ActivityType='21,8,14')
                 set @sqlQuery = @sqlQuery +  ' , S.CreditType as [Credit Type] '
             
             set @sqlQuery = @sqlQuery +  ' FROM dbo.Chains INNER JOIN
											datatrue_report.dbo.StoreTransactions S ON dbo.Chains.ChainID = S.ChainID INNER JOIN
											dbo.Stores ON S.StoreID = dbo.Stores.StoreID  INNER JOIN 
											dbo.Products ON S.ProductID = dbo.Products.ProductID INNER JOIN
											dbo.ProductBrandAssignments PB on PB.ProductID=dbo.Products.ProductID Inner Join 
											dbo.Brands ON PB.BrandID = dbo.Brands.BrandID INNER JOIN
											dbo.Suppliers ON dbo.Suppliers.SupplierID = S.SupplierID INNER JOIN
											dbo.TransactionTypes on dbo.TransactionTypes.TransactionTypeId = S.TransactionTypeID inner join
											SupplierBanners SB on SB.SupplierId = Suppliers.SupplierId and SB.Status=''Active'' and SB.Banner=Stores.Custom1 
											inner join 	dbo.ProductIdentifiers ON dbo.Products.ProductID = dbo.ProductIdentifiers.ProductID and ProductIdentifiers.ProductIdentifierTypeId in (2,8)
											left outer join dbo.ProductIdentifiers PD on dbo.Products.ProductID = PD.ProductID and PD.ProductIdentifierTypeId =3 and PD.OwnerEntityId=S.SupplierID
											LEFT OUTER JOIN  dbo.StoresUniqueValues SUV ON S.SupplierID = SUV.SupplierID AND S.StoreID=SUV.StoreID
											left JOIN Warehouses WH ON WH.ChainID=Chains.ChainID and WH.WarehouseId=SUV.DistributionCenter
											WHERE  1=1 and Cast(S.SaleDateTime as date) between Cast(Stores.ActiveFromDate as date) and Cast(Stores.ActiveLastDate as date)'

            if(@ChainId <>'-1')
                set @sqlQuery = @sqlQuery +  ' and dbo.chains.ChainID=' + @ChainId
         
            if(@SupplierID <>'-1')
                set @sqlQuery = @sqlQuery +  ' and Suppliers.SupplierId=' + @SupplierId
         
            if(@custom1='')
                set @sqlQuery = @sqlQuery + ' and Stores.custom1 is Null'
            else if(@custom1<>'-1')
                set @sqlQuery = @sqlQuery + ' and Stores.custom1=''' + @custom1 + ''''
         
            if(@ActivityType <>'-1')
                set @sqlQuery = @sqlQuery +  ' and S.TransactionTypeID in (' + @ActivityType + ')'
         
            if(@CreditType = '0')
                set @sqlQuery = @sqlQuery +  ' and S.CreditType is NULL '
           
            else if(@CreditType <> '-1')                
                set @sqlQuery = @sqlQuery +  ' and S.CreditType = ''' + @CreditType + ''''
           
            if(@BrandId<>'-1')
                set @sqlQuery = @sqlQuery +  ' and Brands.BrandId=' + @BrandId
         
            if(@SupplierInvoiceNumber<>'-1')
                set @sqlQuery = @sqlQuery +  ' and S.SupplierInvoiceNumber=''' + @SupplierInvoiceNumber + ''''
               
            if (convert(date, @TransFromDate  ) > convert(date,'1900-01-01'))
                set @sqlQuery = @sqlQuery + ' and S.SaleDateTime  >= ''' + @TransFromDate  + ''''
         
            if(convert(date, @TransToDate ) > convert(date,'1900-01-01'))
                set @sqlQuery = @sqlQuery + ' and S.SaleDateTime  <=''' + @TransToDate  + ''''

            if(@ProductIdentifierValue<>'')
			 begin

				-- 2 = UPC, 3 = Product Name , 7 = Vendor Item Number
				if (@ProductIdentifierType=2)
					 set @sqlQuery = @sqlQuery + ' and ProductIdentifiers.IdentifierValue like ''%' + @ProductIdentifierValue + '%'''
			         
				else if (@ProductIdentifierType=3)
					set @sqlQuery = @sqlQuery + ' and dbo.Products.ProductName like ''%' + @ProductIdentifierValue + '%'''
					
				else if (@ProductIdentifierType=7)
					 set @sqlQuery = @sqlQuery + ' and PD.IdentifierValue like ''%' + @ProductIdentifierValue + '%'''
			 end
            
            
            if(@StoreIdentifierValue<>'')
                begin
                    -- 1 = Store Number, 2 = SBT Number, 3 = Store Name
                    if (@StoreIdentifierType=1)
                        set @sqlQuery = @sqlQuery + ' and stores.storeidentifier like ''%' + @StoreIdentifierValue + '%'''
                    else if (@StoreIdentifierType=2)
                        set @sqlQuery = @sqlQuery + ' and stores.Custom2 like ''%' + @StoreIdentifierValue + '%'''
                    else if (@StoreIdentifierType=3)
                        set @sqlQuery = @sqlQuery + ' and stores.StoreName like ''%' + @StoreIdentifierValue + '%'''
                end
         
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
           
            if (@ShowAggregate=1)   
            begin
                set @sqlQuery = @sqlQuery + ' group by dbo.Suppliers.SupplierName, dbo.TransactionTypes.transactiontypeid, dbo.Products.ProductName, 
												dbo.ProductIdentifiers.IdentifierValue, 
												PD.IdentifierValue, dbo.Brands.BrandName, dbo.TransactionTypes.TransactionTypeName, 
												S.rulecost, S.Promoallowance,  S.SaleDateTime '
               
                if (@ActivityType='21,8,14')
                     set @sqlQuery = @sqlQuery +  ' , S.CreditType '
            end         
            set @sqlQuery = @sqlQuery +  ' order by saledatetime asc, upc desc     '
    end
    
    print @sqlQuery;
    exec(@sqlQuery);
 
End
GO
