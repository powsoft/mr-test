USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_StoreActivities_WeekEnd]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/* 
exec [usp_StoreActivities_NPShrink] '75221', '79838', 'Maverik', '5,9,20,10,11,12,15,21,8,14,5,9,20,21,8,14,2,6,7,16,17,18,19,22,23,-999,24,26,25,27', '-1', '10/13/2014','11/30/2014',2,'',1,'',1,'',0,'-1','-1','','','-1'
exec [usp_StoreActivities_NPShrink] '60624', '26645', 'Cumberland Farms', '5,9,20,10,11,12,15,21,8,14,5,9,20,21,8,14,2,6,7,16,17,18,19,22,23,-999,24,26,25,27', '-1', '10/13/2014','11/30/2014',2,'',1,'',1,'',1,'-1','-1','','','-1'
exec [usp_StoreActivities_WeekEnd] '40393', '-1', '-1', '24,26,25', '-1', '01/01/1900','01/01/1900',2,'',1,'',1,'',2,'-1','-1','','','-1','SaleDate'
exec [usp_StoreActivities_WeekEnd] '40393', '-1', '-1', '24,26,25', '-1', '01/01/1900','01/01/1900',2,'',1,'',1,'',2,'-1','-1','','','-1','WeekEndDate'
*/

CREATE procedure [dbo].[usp_StoreActivities_WeekEnd]
 @ChainId varchar(5),
 @SupplierID varchar(5),
 @custom1 varchar(255),
 @ActivityType varchar(255),
 @BrandId varchar(5),
 @TransFromDate varchar(50),
 @TransToDate varchar(50),
 @ProductIdentifierType int,
 @ProductIdentifierValue varchar(250),
 @StoreIdentifierType int,
 @StoreIdentifierValue varchar(250),
 @OtherOption int,
 @Others varchar(250),
 @ShowAggregate int,
 @SupplierInvoiceNumber varchar(50),
 @CreditType varchar(20),
 @SupplierIdentifierValue varchar(50),
 @RetailerIdentifierValue varchar(50),
 @CategoryType int,
 @ViewBy Varchar(20)
 
as
Begin
	Declare @sqlQuery varchar(max)
	Declare @sqlQueryShrink varchar(max)
	Declare @sqlQueryNPShrink varchar(max)
	Declare @CostFormat varchar(10)
	
	IF(@supplierID<>'-1')
		Select @CostFormat = Costformat from SupplierFormat where SupplierID = @supplierID
	else
		set @CostFormat=4
 
	set @CostFormat = ISNULL(@CostFormat, 4)
 
	/****** Store Activities Query for Activitiy Type Shrink ********/
    set @sqlQueryShrink = 'select C.ChainName as [Retailer Name],SupplierName as [Supplier Name] '
	if (@ShowAggregate=0)
        set @sqlQueryShrink = @sqlQueryShrink +' ,ST.Custom1 as Banner, 
										ST.StoreName as Store,
										ST.Custom2 as [SBT Number],  
										ST.StoreIdentifier as [Store No],
										'''' as [Supplier Doc No],
										P.ProductName as Product, 
										I.UPC,0 as [Retail Price],DataTrue_CustomResultSets.dbo.tmpProductsSuppliersItemsConversion.SupplierProductID 
										as [Vendor Item Number] '
	else if (@ShowAggregate=1)
        set @sqlQueryShrink = @sqlQueryShrink +  ' ,P.ProductName as Product,I.UPC,
										DataTrue_CustomResultSets.dbo.tmpProductsSuppliersItemsConversion.SupplierProductID 
										as [Vendor Item Number] '
    else if (@ShowAggregate=2)
        set @sqlQueryShrink = @sqlQueryShrink + ' ,ST.Custom1 as Banner,ST.StoreName as Store,
										ST.Custom2 as [SBT Number],  
										ST.StoreIdentifier as [Store No],
										'''' as [Supplier Doc No]'
										
   set @sqlQueryShrink = @sqlQueryShrink + ' ,B.BrandName as Brand,
									''Shrink'' as Type, 
									convert(varchar(10), I.PhysicalInventoryDate, 101) as [Transaction Date], 
									I.ShrinkUnits as Qty '
									
	if (@ShowAggregate>0)
        set @sqlQueryShrink = @sqlQueryShrink + ' ,cast(I.WeightedAvgCost as numeric(10, ' + @CostFormat + '))  as [Total Ext Cost],'''' as [Total Ext Promo],
									   cast(I.WeightedAvgCost as numeric(10, ' + @CostFormat + '))  as [Total Net Cost]  '
        
    else 
        set @sqlQueryShrink = @sqlQueryShrink + ' ,cast(I.WeightedAvgCost as numeric(10, ' + @CostFormat + '))  as Cost,'''' as Promo,
									   cast(I.WeightedAvgCost as numeric(10, ' + @CostFormat + '))  as [Net Cost] '

     if (EXISTS(Select @ActivityType Where @ActivityType LIKE '%21,8,14%'))
          set @sqlQueryShrink = @sqlQueryShrink +  ' , '''' as [Credit Type] '
     
      if (EXISTS(Select @ActivityType Where @ActivityType LIKE '%21,8,14%') or EXISTS(Select @ActivityType Where @ActivityType LIKE '%2,6,7,16%') or EXISTS(Select @ActivityType Where @ActivityType LIKE '%5,9,20%'))
          set @sqlQueryShrink = @sqlQueryShrink +  ' , '''' as [Alternative Store #] '
                  
	if (@ShowAggregate<>1)                     
        set @sqlQueryShrink = @sqlQueryShrink +  ' ,'''' as [Distribution Center], '''' as [Regional Manager], 
										'''' as [Sales Representative]
										,I.SupplierAcctNo as [Supplier Acct Number],
									   '''' as [Driver Name], 
									   ''''  as [Route Number] '	
									   					                               
		set @sqlQueryShrink = @sqlQueryShrink + ' from InventorySettlementRequests I  WITH(NOLOCK) 
											inner join Suppliers S  WITH(NOLOCK) on S.SupplierID=I.supplierId
											inner join Stores ST  WITH(NOLOCK) on ST.StoreID=I.StoreID and ST.ActiveStatus=''Active''
											INNER JOIN Chains C  WITH(NOLOCK) ON C.ChainID=ST.ChainID
											inner join Products P  WITH(NOLOCK) on P.ProductID=I.ProductID 
											inner join SupplierBanners SB  WITH(NOLOCK) on SB.SupplierId = S.SupplierId and SB.Status=''Active'' and SB.Banner=ST.Custom1 
											left join ProductBrandAssignments PB WITH(NOLOCK)  on PB.ProductID=P.ProductID and PB.CustomOwnerEntityId= S.SupplierID 
											left join Brands B WITH(NOLOCK) ON PB.BrandID = B.BrandID  
											left outer join dbo.ProductIdentifiers PD WITH(NOLOCK)  on P.ProductID = PD.ProductID and PD.ProductIdentifierTypeId =3 
											left join DataTrue_CustomResultSets..tmpProductsSuppliersItemsConversion  WITH(NOLOCK) 
											on DataTrue_CustomResultSets..tmpProductsSuppliersItemsConversion.ProductID=P.ProductID
											and DataTrue_CustomResultSets..tmpProductsSuppliersItemsConversion.SupplierID=S.SupplierID
										where 1=1 '
     
     if(@ChainId <>'-1')
        set @sqlQueryShrink = @sqlQueryShrink +  ' and ST.ChainID=' + @ChainId
 
    if(@SupplierID <>'-1')
        set @sqlQueryShrink = @sqlQueryShrink +  ' and I.SupplierId=' + @SupplierId
 
    if(@custom1='')
        set @sqlQueryShrink = @sqlQueryShrink + ' and ST.custom1 is Null'
    else if(@custom1<>'-1')
        set @sqlQueryShrink = @sqlQueryShrink + ' and ST.custom1=''' + @custom1 + ''''
       
    if (convert(date, @TransFromDate  ) > convert(date,'1900-01-01'))
        set @sqlQueryShrink = @sqlQueryShrink + ' and I.PhysicalInventoryDate  >= ''' + @TransFromDate  + ''''
 
    if(convert(date, @TransToDate ) > convert(date,'1900-01-01'))
        set @sqlQueryShrink = @sqlQueryShrink + ' and I.PhysicalInventoryDate  <=''' + @TransToDate  + ''''

	 if(@ProductIdentifierValue<>'')
	 begin

		-- 2 = UPC, 3 = Product Name 
		if (@ProductIdentifierType=2)
			 set @sqlQueryShrink = @sqlQueryShrink + ' and I.UPC ' + @ProductIdentifierValue 
	         
		else if (@ProductIdentifierType=3)
			 set @sqlQueryShrink = @sqlQueryShrink + ' and P.ProductName ' + @ProductIdentifierValue 
			
		else if (@ProductIdentifierType=7)
			 set @sqlQueryShrink = @sqlQueryShrink + ' and DataTrue_CustomResultSets.dbo.tmpProductsSuppliersItemsConversion.SupplierProductID ' + @ProductIdentifierValue 
	 end

    
    if(@StoreIdentifierValue<>'')
        begin
            -- 1 = Store Number, 2 = SBT Number, 3 = Store Name
            if (@StoreIdentifierType=1)
                set @sqlQueryShrink = @sqlQueryShrink + ' and ST.storeidentifier ' + @StoreIdentifierValue
            else if (@StoreIdentifierType=2)
                set @sqlQueryShrink = @sqlQueryShrink + ' and ST.Custom2 ' + @StoreIdentifierValue 
            else if (@StoreIdentifierType=3)
                set @sqlQueryShrink = @sqlQueryShrink + ' and ST.StoreName ' + @StoreIdentifierValue 
        end
       

    set @sqlQueryShrink = @sqlQueryShrink + ' Union ALL '
     
     set @sqlQueryShrink = @sqlQueryShrink + ' select C.ChainName as [Retailer Name], MR.SupplierName as [Supplier Name]'
     if (@ShowAggregate=0)
        set @sqlQueryShrink = @sqlQueryShrink +  ' ,MR.Banner,
										 ST.StoreName as Store, ST.Custom2 as [SBT Number],  ST.StoreIdentifier as [Store No],
										'''' as [Supplier Doc No],
										P.ProductName as Product, MR.UPC,MR.[RuleRetail] as [Retail Price],
										DataTrue_CustomResultSets.dbo.tmpProductsSuppliersItemsConversion.SupplierProductID 
										as [Vendor Item Number]'
       else if (@ShowAggregate=1)
        set @sqlQueryShrink = @sqlQueryShrink +  ' ,P.ProductName as Product, MR.UPC,
										DataTrue_CustomResultSets.dbo.tmpProductsSuppliersItemsConversion.SupplierProductID as [Vendor Item Number]'
        
       else if (@ShowAggregate=2)
        set @sqlQueryShrink = @sqlQueryShrink + ' ,MR.Banner,
									  ST.StoreName as Store, ST.Custom2 as [SBT Number],  ST.StoreIdentifier as [Store No],
									  '''' as [Supplier Doc No]'
         
        set @sqlQueryShrink = @sqlQueryShrink +  ' ,B.BrandName as Brand,
										''Pending Shrink'' as Type, convert(varchar(10),MR.LastInventoryCountDate, 101) as [Transaction Date], 
										MR.ShrinkUnits as Qty '	
										
		if (@ShowAggregate>0)
			set @sqlQueryShrink = @sqlQueryShrink + ' ,cast(MR.WeightedAvgCost as numeric(10, ' + @CostFormat + ')) as [Total Ext Cost],'''' as [Total Ext Promo],
									   cast(MR.WeightedAvgCost as numeric(10, ' + @CostFormat + '))  as [Total Net Cost] '
        
	   else 
			set @sqlQueryShrink = @sqlQueryShrink + ' ,cast(MR.WeightedAvgCost as numeric(10, ' + @CostFormat + ')) as Cost,'''' as Promo,
									  cast(MR.WeightedAvgCost as numeric(10, ' + @CostFormat + '))  as [Net Cost] '
        
      if (EXISTS(Select @ActivityType Where @ActivityType LIKE '%21,8,14%'))
          set @sqlQueryShrink = @sqlQueryShrink +  ' , '''' as [Credit Type] '
     
      if (EXISTS(Select @ActivityType Where @ActivityType LIKE '%21,8,14%') or EXISTS(Select @ActivityType Where @ActivityType LIKE '%2,6,7,16%') or EXISTS(Select @ActivityType Where @ActivityType LIKE '%5,9,20%'))
          set @sqlQueryShrink = @sqlQueryShrink +  ' , '''' as [Alternative Store #] '
          																			
	   if (@ShowAggregate<>1)                     
		  set @sqlQueryShrink = @sqlQueryShrink +  ' ,'''' as [Distribution Center], '''' as [Regional Manager], 
										'''' as [Sales Representative]
										,MR.SupplierAcctNo as [Supplier Acct Number],
										'''' as [Driver Name], ''''  as [Route Number] '
										
		set @sqlQueryShrink = @sqlQueryShrink +  '	from InventoryReport_New_FactTable_Active  MR WITH(NOLOCK) 
											inner join Stores ST WITH(NOLOCK) on ST.StoreID=MR.StoreID
											INNER JOIN Chains C WITH(NOLOCK) ON C.ChainID=ST.ChainID
											inner join Products P WITH(NOLOCK) on P.ProductID=MR.ProductID
											inner join SupplierBanners SB WITH(NOLOCK) on SB.SupplierId = MR.SupplierId and SB.Status=''Active'' 
											and SB.Banner=ST.Custom1
											left join ProductBrandAssignments PB WITH(NOLOCK) on  PB.ProductID=P.ProductID  and 
											PB.CustomOwnerEntityId= MR.SupplierID 
											left join Brands B WITH(NOLOCK) ON PB.BrandID = B.BrandID 
											left outer join dbo.ProductIdentifiers PD WITH(NOLOCK) on P.ProductID = PD.ProductID and 
											PD.ProductIdentifierTypeId =3 
											and PD.OwnerEntityId=MR.SupplierID
											left join DataTrue_CustomResultSets..tmpProductsSuppliersItemsConversion WITH(NOLOCK) 
											on DataTrue_CustomResultSets..tmpProductsSuppliersItemsConversion.ProductID=P.ProductID
										where LastInventoryCountDate > (select MAX(PhysicalInventoryDate) from InventorySettlementRequests I
										where I.supplierId=MR.SupplierID and I.StoreID=MR.StoreID and I.ProductID=MR.ProductID)'

    if(@ChainId <>'-1')
        set @sqlQueryShrink = @sqlQueryShrink +  ' and ST.ChainID=' + @ChainId
 
    if(@SupplierID <>'-1')
        set @sqlQueryShrink = @sqlQueryShrink +  ' and MR.SupplierId=' + @SupplierId
 
    if(@custom1='')
        set @sqlQueryShrink = @sqlQueryShrink + ' and ST.custom1 is Null'
    else if(@custom1<>'-1')
        set @sqlQueryShrink = @sqlQueryShrink + ' and ST.custom1=''' + @custom1 + ''''
       
    if (convert(date, @TransFromDate  ) > convert(date,'1900-01-01'))
        set @sqlQueryShrink = @sqlQueryShrink + ' and MR.LastInventoryCountDate  >= ''' + @TransFromDate  + ''''
 
    if(convert(date, @TransToDate ) > convert(date,'1900-01-01'))
        set @sqlQueryShrink = @sqlQueryShrink + ' and MR.LastInventoryCountDate  <=''' + @TransToDate  + ''''

 
    if(@ProductIdentifierValue<>'')
	 begin

		-- 2 = UPC, 3 = Product Name 
		if (@ProductIdentifierType=2)
			 set @sqlQueryShrink = @sqlQueryShrink + ' and MR.UPC ' + @ProductIdentifierValue 
	         
		else if (@ProductIdentifierType=3)
			set @sqlQueryShrink = @sqlQueryShrink + ' and P.ProductName ' + @ProductIdentifierValue 
		
		else if (@ProductIdentifierType=7)
			 set @sqlQueryShrink = @sqlQueryShrink + ' and DataTrue_CustomResultSets.dbo.tmpProductsSuppliersItemsConversion.SupplierProductID ' + @ProductIdentifierValue 
	 end
 
    if(@StoreIdentifierValue<>'')
        begin
            -- 1 = Store Number, 2 = SBT Number, 3 = Store Name
            if (@StoreIdentifierType=1)
                set @sqlQueryShrink = @sqlQueryShrink + ' and ST.storeidentifier ' + @StoreIdentifierValue 
            else if (@StoreIdentifierType=2)
                set @sqlQueryShrink = @sqlQueryShrink + ' and ST.Custom2 ' + @StoreIdentifierValue 
            else if (@StoreIdentifierType=3)
                set @sqlQueryShrink = @sqlQueryShrink + ' and ST.StoreName ' + @StoreIdentifierValue 
        end
       
        set @sqlQueryShrink = @sqlQueryShrink + ' Union ALL '
     
     
     set @sqlQueryShrink = @sqlQueryShrink + ' select C.ChainName as [Retailer Name], MR.SupplierName as [Supplier Name]'
     if (@ShowAggregate=0)
        set @sqlQueryShrink = @sqlQueryShrink + ' ,MR.Banner,
									 ST.StoreName as Store, ST.Custom2 as [SBT Number],  ST.StoreIdentifier as [Store No],
									 '''' as [Supplier Doc No],
									 P.ProductName as Product, MR.UPC,MR.[RuleRetail] as [Retail Price],
									 DataTrue_CustomResultSets.dbo.tmpProductsSuppliersItemsConversion.SupplierProductID 
									 as [Vendor Item Number]'
      else if (@ShowAggregate=1)
        set @sqlQueryShrink = @sqlQueryShrink +  ' ,P.ProductName as Product, MR.UPC,
                                     DataTrue_CustomResultSets.dbo.tmpProductsSuppliersItemsConversion.SupplierProductID 
                                     as [Vendor Item Number]'
     else if (@ShowAggregate=2)
        set @sqlQueryShrink = @sqlQueryShrink +  ' ,MR.Banner,
                                     ST.StoreName as Store, ST.Custom2 as [SBT Number],  ST.StoreIdentifier as [Store No],
                                     '''' as [Supplier Doc No]'
           
       set @sqlQueryShrink = @sqlQueryShrink +' ,B.BrandName as Brand,
                                    ''Pending Shrink'' as Type, convert(varchar(10),MR.LastInventoryCountDate, 101) as [Transaction Date], 
                                    MR.ShrinkUnits as Qty '
                                    
       if (@ShowAggregate>0)
        set @sqlQueryShrink = @sqlQueryShrink + ' ,cast(MR.WeightedAvgCost as numeric(10, ' + @CostFormat + ')) as [Total Ext Cost],'''' as [Total Ext Promo],
									   cast(MR.WeightedAvgCost as numeric(10, ' + @CostFormat + '))  as [Total Net Cost] '
        
	   else 
        set @sqlQueryShrink = @sqlQueryShrink + ' ,cast(MR.WeightedAvgCost as numeric(10, ' + @CostFormat + '))  as Cost, '''' as Promo,
									   cast(MR.WeightedAvgCost as numeric(10, ' + @CostFormat + '))  as [Net Cost] '
	  
	   if (EXISTS(Select @ActivityType Where @ActivityType LIKE '%21,8,14%'))
          set @sqlQueryShrink = @sqlQueryShrink +  ' , '''' as [Credit Type] '
     
       if (EXISTS(Select @ActivityType Where @ActivityType LIKE '%21,8,14%') or EXISTS(Select @ActivityType Where @ActivityType LIKE '%2,6,7,16%') or EXISTS(Select @ActivityType Where @ActivityType LIKE '%5,9,20%'))
          set @sqlQueryShrink = @sqlQueryShrink +  ' , '''' as [Alternative Store #] '
                                      
                                    
       if (@ShowAggregate<>1)                     
        set @sqlQueryShrink = @sqlQueryShrink +  ' ,'''' as [Distribution Center], '''' as [Regional Manager], 
										'''' as [Sales Representative]
										,MR.SupplierAcctNo as [Supplier Acct Number],
										'''' as [Driver Name], ''''  as [Route Number] '
                                    
        set @sqlQueryShrink = @sqlQueryShrink +  ' from  InventoryReport_New_FactTable_Active MR WITH(NOLOCK)
										 inner join Stores ST WITH(NOLOCK) on ST.StoreID=MR.StoreID
										 INNER JOIN Chains C WITH(NOLOCK) ON C.ChainID=ST.ChainID
										 inner join Products P WITH(NOLOCK) on P.ProductID=MR.ProductID
										 inner join SupplierBanners SB WITH(NOLOCK) on SB.SupplierId = MR.SupplierId and SB.Status=''Active'' and SB.Banner=ST.Custom1
										 left join ProductBrandAssignments PB WITH(NOLOCK) on PB.ProductID=P.ProductID and PB.CustomOwnerEntityId= MR.SupplierID 
										 left join Brands B WITH(NOLOCK) ON PB.BrandID = B.BrandID 
										 left outer join dbo.ProductIdentifiers PD  WITH(NOLOCK)
												on P.ProductID = PD.ProductID and PD.ProductIdentifierTypeId =3 and PD.OwnerEntityId=MR.SupplierID
										left join DataTrue_CustomResultSets..tmpProductsSuppliersItemsConversion WITH(NOLOCK) 
												on DataTrue_CustomResultSets..tmpProductsSuppliersItemsConversion.ProductID=P.ProductID
										 left join InventorySettlementRequests  I WITH(NOLOCK) on I.supplierId=MR.SupplierID
										 and I.StoreID=MR.StoreID and I.ProductID=MR.ProductID
									where I.supplierId is null '
   
    if(@ChainId <>'-1')
        set @sqlQueryShrink = @sqlQueryShrink +  ' and ST.ChainID=' + @ChainId
 
    if(@SupplierID <>'-1')
        set @sqlQueryShrink = @sqlQueryShrink +  ' and MR.SupplierId=' + @SupplierId
 
    if(@custom1='')
        set @sqlQueryShrink = @sqlQueryShrink + ' and ST.custom1 is Null'
    else if(@custom1<>'-1')
        set @sqlQueryShrink = @sqlQueryShrink + ' and ST.custom1=''' + @custom1 + ''''
       
    if (convert(date, @TransFromDate  ) > convert(date,'1900-01-01'))
        set @sqlQueryShrink = @sqlQueryShrink + ' and MR.LastInventoryCountDate  >= ''' + @TransFromDate  + ''''
 
    if(convert(date, @TransToDate ) > convert(date,'1900-01-01'))
        set @sqlQueryShrink = @sqlQueryShrink + ' and MR.LastInventoryCountDate  <=''' + @TransToDate  + ''''

 
    if(@ProductIdentifierValue<>'')
	 begin

		-- 2 = UPC, 3 = Product Name , 7= Vendor Item Number
		if (@ProductIdentifierType=2)
			 set @sqlQueryShrink = @sqlQueryShrink + ' and MR.UPC ' + @ProductIdentifierValue
	         
		else if (@ProductIdentifierType=3)
			set @sqlQueryShrink = @sqlQueryShrink + ' and P.ProductName ' + @ProductIdentifierValue
			
		else if (@ProductIdentifierType=7)
			 set @sqlQueryShrink = @sqlQueryShrink + ' and DataTrue_CustomResultSets.dbo.tmpProductsSuppliersItemsConversion.SupplierProductID ' + @ProductIdentifierValue
	 end 
 
    if(@StoreIdentifierValue<>'')
        begin
            -- 1 = Store Number, 2 = SBT Number, 3 = Store Name
            if (@StoreIdentifierType=1)
                set @sqlQueryShrink = @sqlQueryShrink + ' and ST.storeidentifier ' + @StoreIdentifierValue 
            else if (@StoreIdentifierType=2)
                set @sqlQueryShrink = @sqlQueryShrink + ' and ST.Custom2 ' + @StoreIdentifierValue 
            else if (@StoreIdentifierType=3)
                set @sqlQueryShrink = @sqlQueryShrink + ' and ST.StoreName ' + @StoreIdentifierValue 
        end
   


	/****** Store Activities Query for other Activities ********/
	
	 set @sqlQuery = 'SELECT  distinct dbo.Chains.ChainName as [Retailer Name], dbo.Suppliers.SupplierName as [Supplier Name], '
             
     if (@ShowAggregate=0)
        set @sqlQuery = @sqlQuery +  'dbo.Stores.custom1 as Banner, dbo.Stores.StoreName as Store,
									  dbo.Stores.Custom2 as [SBT Number],  dbo.Stores.StoreIdentifier as [Store No], 
									  isnull(S.SupplierInvoiceNumber,'''') as [Supplier Doc No], dbo.Products.ProductName as Product, 
									  dbo.ProductIdentifiers.IdentifierValue as UPC,s.RuleRetail as [Retail Price],
									  case when dbo.ProductIdentifiers.ProductIdentifierTypeId=2 then S.SupplierItemNumber  else 
									  (select C.SupplierProductID from DataTrue_CustomResultSets.dbo.tmpProductsSuppliersItemsConversion C with (nolock)
									  where c.ProductId=Products.ProductID and C.SupplierID=Suppliers.SupplierId) end as [Vendor Item Number], '
     
     else if (@ShowAggregate=1)
        set @sqlQuery = @sqlQuery +  ' dbo.Products.ProductName as Product, 
									  dbo.ProductIdentifiers.IdentifierValue as UPC,
									  case when dbo.ProductIdentifiers.ProductIdentifierTypeId=2 then S.SupplierItemNumber  else 
									  (select C.SupplierProductID from DataTrue_CustomResultSets.dbo.tmpProductsSuppliersItemsConversion C with (nolock)
									  where c.ProductId=Products.ProductID and C.SupplierID=Suppliers.SupplierId) end as [Vendor Item Number], '
	
	else if (@ShowAggregate=2)
        set @sqlQuery = @sqlQuery +  'dbo.Stores.custom1 as Banner, dbo.Stores.StoreName as Store,
									  dbo.Stores.Custom2 as [SBT Number], dbo.Stores.StoreIdentifier as [Store No], 
									  isnull(S.SupplierInvoiceNumber,'''') as [Supplier Doc No], '                                  
                          
     set @sqlQuery = @sqlQuery +  ' dbo.Brands.BrandName as Brand,dbo.TransactionTypes.TransactionTypeName as Type, '
     
     IF(@ViewBy='SaleDate')
		SET @sqlQuery = @sqlQuery +  ' convert(varchar(10),S.SaleDateTime, 101) as [Transaction Date], '
     ELSE IF(@ViewBy='WeekEndDate')
		SET @sqlQuery = @sqlQuery +  ' Convert(varchar(12),dbo.GetWeekEnd(S.SaleDateTime,dbo.Stores.ChainID,dbo.Suppliers.SupplierID),101) as [Transaction Date], '
		
     set @sqlQuery = @sqlQuery +  ' case when dbo.TransactionTypes.transactiontypeid in (21,8,14) then -sum(S.Qty) else sum(S.Qty) end as Qty, '
									
	  if (@ShowAggregate>0)
		 set @sqlQuery = @sqlQuery + '  cast(sum(S.rulecost*s.Qty) as numeric(10, ' + @CostFormat + ')) as [Total Ext Cost],sum(S.Promoallowance*s.Qty) as [Total Ext Promo],
									   cast((sum(isnull(S.rulecost*s.Qty,0))-sum(isnull(S.Promoallowance*s.Qty,0))) as numeric(10, ' + @CostFormat + ')) as [Total Net Cost] '
	 else 
		 set @sqlQuery = @sqlQuery + ' cast(S.rulecost as numeric(10, ' + @CostFormat + ')) as Cost, S.Promoallowance as Promo,
									   cast((isnull(S.rulecost,0)-isnull(S.Promoallowance,0)) as numeric(10, ' + @CostFormat + ')) as [Net Cost] '					
     
     if (EXISTS(Select @ActivityType Where @ActivityType LIKE '%21,8,14%'))
         set @sqlQuery = @sqlQuery +  ' , S.CreditType as [Credit Type] '
     
       if (EXISTS(Select @ActivityType Where @ActivityType LIKE '%21,8,14%') or EXISTS(Select @ActivityType Where @ActivityType LIKE '%2,6,7,16%') or EXISTS(Select @ActivityType Where @ActivityType LIKE '%5,9,20%'))
         set @sqlQuery = @sqlQuery +  ' , dbo.Stores.Custom4 as [Alternative Store #] '
     
     if (@ShowAggregate<>1)                     
        set @sqlQuery = @sqlQuery +  ' , WH.WarehouseName as [Distribution Center], SUV.RegionalMgr as [Regional Manager], 
										SUV.SalesRep as [Sales Representative], SUV.supplieraccountnumber as [Supplier Acct Number], 
										SUV.DriverName as [Driver Name], SUV.RouteNumber as [Route Number] '
     
		set @sqlQuery = @sqlQuery +  ' FROM dbo.Chains  WITH(NOLOCK) 
										INNER JOIN dbo.StoreTransactions S WITH(NOLOCK) ON dbo.Chains.ChainID = S.ChainID 
										INNER JOIN dbo.Stores  WITH(NOLOCK) ON S.StoreID = dbo.Stores.StoreID 
										INNER JOIN  dbo.Products  WITH(NOLOCK) ON S.ProductID = dbo.Products.ProductID 
										INNER JOIN dbo.Suppliers  WITH(NOLOCK) ON dbo.Suppliers.SupplierID = S.SupplierID 
										INNER JOIN dbo.TransactionTypes  WITH(NOLOCK) on dbo.TransactionTypes.TransactionTypeId = S.TransactionTypeID 
										inner join SupplierBanners SB  WITH(NOLOCK) on SB.SupplierId = Suppliers.SupplierId and SB.Status=''Active'' 
										and SB.Banner=Stores.Custom1 
										inner join dbo.ProductIdentifiers  WITH(NOLOCK) ON dbo.Products.ProductID = dbo.ProductIdentifiers.ProductID 
										and dbo.ProductIdentifiers.IdentifierValue = s.UPC
										left join dbo.ProductBrandAssignments PB  WITH(NOLOCK) on PB.ProductID=dbo.Products.ProductID 
										and PB.CustomOwnerEntityId= S.SupplierID 
										left join dbo.Brands  WITH(NOLOCK) ON PB.BrandID = dbo.Brands.BrandID 
										left outer join dbo.ProductIdentifiers PD  WITH(NOLOCK) on dbo.Products.ProductID = PD.ProductID 
										and PD.ProductIdentifierTypeId =3 and PD.OwnerEntityId=S.SupplierID'
	if (@ProductIdentifierType=8)
		set @sqlQuery = @sqlQuery + ' left outer join dbo.ProductIdentifiers PD1  WITH(NOLOCK) on dbo.Products.ProductID = PD1.ProductID and PD1.ProductIdentifierTypeId =8  '

		set @sqlQuery = @sqlQuery + ' LEFT OUTER JOIN  dbo.StoresUniqueValues SUV  WITH(NOLOCK) ON S.SupplierID = SUV.SupplierID AND S.StoreID=SUV.StoreID
									left JOIN Warehouses WH  WITH(NOLOCK) ON WH.ChainID=Chains.ChainID and WH.WarehouseId=SUV.DistributionCenter
									WHERE  1=1 and Cast(S.SaleDateTime as date) between Cast(Stores.ActiveFromDate as date) and Cast(Stores.ActiveLastDate as date)'
	
	if (@CategoryType=8) 									
		set @sqlQuery = @sqlQuery +  ' and ProductIdentifiers.ProductIdentifierTypeId = 8 '
	else if (@CategoryType=2) 									
		set @sqlQuery = @sqlQuery +  ' and ProductIdentifiers.ProductIdentifierTypeId = 2 '
	else
		set @sqlQuery = @sqlQuery +  ' and ProductIdentifiers.ProductIdentifierTypeId in (2,8) '
		
    if(@ChainId <>'-1')
        set @sqlQuery = @sqlQuery +  ' and dbo.chains.ChainID=' + @ChainId
 
    if(@SupplierID <>'-1')
        set @sqlQuery = @sqlQuery +  ' and Suppliers.SupplierId=' + @SupplierId
 
    if(@custom1='')
        set @sqlQuery = @sqlQuery + ' and Stores.custom1 is Null'
    else if(@custom1<>'-1')
        set @sqlQuery = @sqlQuery + ' and Stores.custom1=''' + @custom1 + ''''
 
    if(@ActivityType <> '-1')
        set @sqlQuery = @sqlQuery +  ' and S.TransactionTypeID in (' + @ActivityType + ') and  S.TransactionTypeID not in (17,18,19,22,23) '
 
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

		-- 2 = UPC, 3 = Product Name , 7 = Vendor Item Number,8=bipad
		if (@ProductIdentifierType=2)
			 set @sqlQuery = @sqlQuery + ' and ProductIdentifiers.IdentifierValue ' + @ProductIdentifierValue 	
	         
		else if (@ProductIdentifierType=3)
			set @sqlQuery = @sqlQuery + ' and dbo.Products.ProductName ' + @ProductIdentifierValue 	
			
		else if (@ProductIdentifierType=7)
			set @sqlQuery = @sqlQuery + '  and case when dbo.ProductIdentifiers.ProductIdentifierTypeId=2 then S.SupplierItemNumber  else 
			 (select C.SupplierProductID from DataTrue_CustomResultSets.dbo.tmpProductsSuppliersItemsConversion C  with(nolock) 
				where c.ProductId=Products.ProductID and C.SupplierID=Suppliers.SupplierId) end  ' + @ProductIdentifierValue 	
				
		else if (@ProductIdentifierType=8)
		if (@ProductIdentifierValue<> '')
			set @sqlQuery = @sqlQuery + ' and PD1.BiPad ' + @ProductIdentifierValue 	
		end
    
    
    if(@StoreIdentifierValue<>'')
        begin
            -- 1 = Store Number, 2 = SBT Number, 3 = Store Name
            if (@StoreIdentifierType=1)
                set @sqlQuery = @sqlQuery + ' and stores.storeidentifier ' + @StoreIdentifierValue 
            else if (@StoreIdentifierType=2)
                set @sqlQuery = @sqlQuery + ' and stores.Custom2 ' + @StoreIdentifierValue 
            else if (@StoreIdentifierType=3)
                set @sqlQuery = @sqlQuery + ' and stores.StoreName ' + @StoreIdentifierValue 
        end
 
    if(@Others<>'')
    begin
        -- 1 = Distribution Center, 2 = Regional Manager, 3 = Sales Representative
        -- 4 = Supplier Account No, 5 = Driver Name, 6 = Route No
                             
        if (@OtherOption=1)
			set @sqlQuery = @sqlQuery + ' and WH.WarehouseName ' + @Others 
		else if (@OtherOption=2)
			set @sqlQuery = @sqlQuery + ' and SUV.RegionalMgr ' + @Others 
		else if (@OtherOption=3)
			set @sqlQuery = @sqlQuery + ' and SUV.SalesRep ' + @Others 
		else if (@OtherOption=4)
			set @sqlQuery = @sqlQuery + ' and SUV.SupplierAccountNumber ' + @Others 
		else if (@OtherOption=5)
			set @sqlQuery = @sqlQuery + ' and SUV.DriverName ' + @Others 
		else if (@OtherOption=6)
			set @sqlQuery = @sqlQuery + ' and SUV.RouteNumber ' + @Others 

    end
   
   if(@SupplierIdentifierValue<>'')
		set @sqlQuery = @sqlQuery + ' and dbo.Suppliers.SupplierIdentifier like ''%' + @SupplierIdentifierValue + '%'''

   if(@RetailerIdentifierValue<>'')
		set @sqlQuery = @sqlQuery + ' and dbo.Chains.ChainIdentifier like ''%' + @RetailerIdentifierValue + '%'''
    
    set @sqlQuery = @sqlQuery + ' group by dbo.Chains.ChainName, dbo.Suppliers.SupplierName, dbo.TransactionTypes.transactiontypeid, 
								   Suppliers.SupplierId, dbo.Brands.BrandName, dbo.ProductIdentifiers.ProductIdentifierTypeID,dbo.TransactionTypes.TransactionTypeName,'
	 IF(@ViewBy='SaleDate')
		SET @sqlQuery = @sqlQuery +  ' convert(varchar(10),S.SaleDateTime, 101) , '
     ELSE IF(@ViewBy='WeekEndDate')
		SET @sqlQuery = @sqlQuery +  ' Convert(varchar(12),dbo.GetWeekEnd(S.SaleDateTime,dbo.Stores.ChainID,dbo.Suppliers.SupplierID),101) , '
							  
	if (@ShowAggregate<>1)                     
        set @sqlQuery = @sqlQuery +  '  WH.WarehouseName, SUV.RegionalMgr, SUV.SalesRep, SUV.supplieraccountnumber, 
										SUV.DriverName, SUV.RouteNumber,'										  
	if (@ShowAggregate=0)
        set @sqlQuery = @sqlQuery +  ' dbo.Stores.custom1, dbo.Stores.StoreName,S.rulecost, S.Promoallowance,dbo.Stores.Custom2, dbo.Stores.StoreIdentifier, isnull(S.SupplierInvoiceNumber,''''),WH.WarehouseName, SUV.RegionalMgr, SUV.SalesRep, SUV.supplieraccountnumber, SUV.DriverName, SUV.RouteNumber, dbo.Products.ProductName, Products.ProductID, dbo.ProductIdentifiers.IdentifierValue, s.RuleRetail,  dbo.ProductIdentifiers.ProductIdentifierTypeId, S.SupplierItemNumber '
     
     else if (@ShowAggregate=1)
        set @sqlQuery = @sqlQuery +  ' dbo.Products.ProductName, Products.ProductID, 
									  dbo.ProductIdentifiers.IdentifierValue, 
									  dbo.ProductIdentifiers.ProductIdentifierTypeId, S.SupplierItemNumber '
	
	else if (@ShowAggregate=2)
        set @sqlQuery = @sqlQuery +  ' dbo.Stores.custom1, dbo.Stores.StoreName,
									  dbo.Stores.Custom2,  dbo.Stores.StoreIdentifier, 
									  isnull(S.SupplierInvoiceNumber,''''),WH.WarehouseName, SUV.RegionalMgr, SUV.SalesRep,
									  SUV.supplieraccountnumber, SUV.DriverName, SUV.RouteNumber '         
                          										  
	if (EXISTS(Select @ActivityType Where @ActivityType LIKE '%21,8,14%'))
             set @sqlQuery = @sqlQuery +  ' , S.CreditType '
    	
    if (EXISTS(Select @ActivityType Where @ActivityType LIKE '%21,8,14%') or EXISTS(Select @ActivityType Where @ActivityType LIKE '%2,6,7,16%') or EXISTS(Select @ActivityType Where @ActivityType LIKE '%5,9,20%'))
			 set @sqlQuery = @sqlQuery +  ' , dbo.Stores.Custom4 '
                                               
    set @sqlQuery = @sqlQuery +  ' ORDER BY [Transaction Date] ASC ; --convert(varchar(10), S.SaleDateTime, 101) asc '
    
    
    /************** Query For Newspaper Shrink Start (AS per discussion on FB case 21073) *******************/
    
    SET @sqlQueryNPShrink = 'SELECT  distinct dbo.Chains.ChainName as [Retailer Name], dbo.Suppliers.SupplierName as [Supplier Name], '
             
     IF (@ShowAggregate=0)
        SET @sqlQueryNPShrink = @sqlQueryNPShrink +  'dbo.Stores.custom1 as Banner, dbo.Stores.StoreName as Store,
									  dbo.Stores.Custom2 as [SBT Number],  dbo.Stores.StoreIdentifier as [Store No], 
									  isnull(S.SupplierInvoiceNumber,'''') as [Supplier Doc No], dbo.Products.ProductName as Product, 
									  dbo.ProductIdentifiers.IdentifierValue as UPC,s.RuleRetail as [Retail Price],
									  case when dbo.ProductIdentifiers.ProductIdentifierTypeId=2 then S.SupplierItemNumber  else 
									  (select C.SupplierProductID from DataTrue_CustomResultSets.dbo.tmpProductsSuppliersItemsConversion C with (nolock)
									  where c.ProductId=Products.ProductID and C.SupplierID=Suppliers.SupplierId) end as [Vendor Item Number], '
     ELSE IF (@ShowAggregate=1)
        SET @sqlQueryNPShrink = @sqlQueryNPShrink +  ' dbo.Products.ProductName as Product, 
									  dbo.ProductIdentifiers.IdentifierValue as UPC,
									  case when dbo.ProductIdentifiers.ProductIdentifierTypeId=2 then S.SupplierItemNumber  else 
									  (select C.SupplierProductID from DataTrue_CustomResultSets.dbo.tmpProductsSuppliersItemsConversion C with (nolock)
									  where c.ProductId=Products.ProductID and C.SupplierID=Suppliers.SupplierId) end as [Vendor Item Number], '	
	ELSE IF (@ShowAggregate=2)
        SET @sqlQueryNPShrink = @sqlQueryNPShrink +  'dbo.Stores.custom1 as Banner, dbo.Stores.StoreName as Store,
									  dbo.Stores.Custom2 as [SBT Number], dbo.Stores.StoreIdentifier as [Store No], 
									  isnull(S.SupplierInvoiceNumber,'''') as [Supplier Doc No], '                                  
                          
     SET @sqlQueryNPShrink = @sqlQueryNPShrink +  ' dbo.Brands.BrandName as Brand,dbo.TransactionTypes.TransactionTypeName as Type, '
     
     IF(@ViewBy='SaleDate')
		SET @sqlQueryNPShrink = @sqlQueryNPShrink +  ' convert(varchar(10),S.SaleDateTime, 101) as [Transaction Date], '
     ELSE IF(@ViewBy='WeekEndDate')
		SET @sqlQueryNPShrink = @sqlQueryNPShrink +  ' Convert(varchar(12),dbo.GetWeekEnd(S.SaleDateTime,dbo.Stores.ChainID,dbo.Suppliers.SupplierID),101) as [Transaction Date], '
     
     SET @sqlQueryNPShrink = @sqlQueryNPShrink +  ' case when dbo.TransactionTypes.transactiontypeid in (21,8,14,19) then -sum(S.Qty) else sum(S.Qty) end as Qty, '
									
	  IF (@ShowAggregate>0)
		 SET @sqlQueryNPShrink = @sqlQueryNPShrink + '  cast(sum(S.rulecost*s.Qty) as numeric(10, ' + @CostFormat + ')) as [Total Ext Cost],sum(S.Promoallowance*s.Qty) as [Total Ext Promo],
									   cast((sum(isnull(S.rulecost*s.Qty,0))-sum(isnull(S.Promoallowance*s.Qty,0))) as numeric(10, ' + @CostFormat + ')) as [Total Net Cost] '
	 ELSE 
		 SET @sqlQueryNPShrink = @sqlQueryNPShrink + ' cast(S.rulecost as numeric(10, ' + @CostFormat + ')) as Cost, S.Promoallowance as Promo,
									   cast((isnull(S.rulecost,0)-isnull(S.Promoallowance,0)) as numeric(10, ' + @CostFormat + ')) as [Net Cost] '					
     
     IF (EXISTS(Select @ActivityType Where @ActivityType LIKE '%21,8,14%'))
          SET @sqlQueryNPShrink = @sqlQueryNPShrink +  ' , '''' as [Credit Type] '
     
     IF (EXISTS(Select @ActivityType Where @ActivityType LIKE '%21,8,14%') or EXISTS(Select @ActivityType Where @ActivityType LIKE '%2,6,7,16%') or EXISTS(Select @ActivityType Where @ActivityType LIKE '%5,9,20%'))
          SET @sqlQueryNPShrink = @sqlQueryNPShrink +  ' , '''' as [Alternative Store #] '
     
     IF (@ShowAggregate<>1)                     
        SET @sqlQueryNPShrink = @sqlQueryNPShrink +  ' , WH.WarehouseName as [Distribution Center], SUV.RegionalMgr as [Regional Manager], 
										SUV.SalesRep as [Sales Representative], SUV.supplieraccountnumber as [Supplier Acct Number], 
										SUV.DriverName as [Driver Name], SUV.RouteNumber as [Route Number] '
     
		SET @sqlQueryNPShrink = @sqlQueryNPShrink +  ' FROM dbo.Chains  WITH(NOLOCK) 
								INNER JOIN StoreTransactions S on S.ChainID=dbo.Chains.ChainID
								INNER JOIN JobProcesses JP ON JP.ProcessID=S.ProcessID AND JP.JobRunningID=10
								INNER JOIN (
											SELECT ST.ChainID,ST.SupplierID,ST.StoreID,ST.ProductID,ST.ProcessID,SaleDateTime,TransactionTypeID,MAX(StoreTransactionID) AS StoreTransactionID
											FROM StoreTransactions AS ST
											INNER JOIN JobProcesses JP ON JP.ProcessID=ST.ProcessID AND JobRunningID=10 
											WHERE 1=1 AND ST.TransactionTypeID in (17) '
											IF(@ChainId <>'-1')
												SET @sqlQueryNPShrink = @sqlQueryNPShrink +  ' and ST.ChainID=' + @ChainId
			 
											IF(@SupplierID <>'-1')
												SET @sqlQueryNPShrink = @sqlQueryNPShrink +  ' and ST.SupplierId=' + @SupplierId 
												
											set @sqlQueryNPShrink = @sqlQueryNPShrink + ' GROUP BY ST.ChainID,ST.SupplierID,ST.StoreID,ST.ProductID,ST.ProcessID,SaleDateTime,TransactionTypeID
											) AS ST ON ST.StoreTransactionID=S.StoreTransactionID AND ST.ChainID=dbo.Chains.ChainID AND ST.SupplierID=S.SupplierID AND ST.StoreID=S.StoreID AND ST.ProductID=S.ProductID AND ST.SaleDateTime=S.SaleDateTime AND ST.TransactionTypeID=S.TransactionTypeID AND ST.ProcessID=S.ProcessID
								INNER JOIN dbo.Stores  WITH(NOLOCK) ON S.StoreID = dbo.Stores.StoreID AND S.ChainID=dbo.Chains.ChainID
								INNER JOIN  dbo.Products  WITH(NOLOCK) ON S.ProductID = dbo.Products.ProductID 
								INNER JOIN dbo.Suppliers  WITH(NOLOCK) ON dbo.Suppliers.SupplierID = S.SupplierID 
								INNER JOIN SupplierBanners SB  WITH(NOLOCK) on SB.SupplierId = Suppliers.SupplierId AND SB.Status=''Active'' AND SB.Banner=Stores.Custom1 
								INNER JOIN dbo.TransactionTypes  WITH(NOLOCK) on dbo.TransactionTypes.TransactionTypeId = S.TransactionTypeID 
								INNER JOIN dbo.ProductIdentifiers  WITH(NOLOCK) ON dbo.Products.ProductID = dbo.ProductIdentifiers.ProductID AND ProductIdentifiers.ProductIdentifierTypeId in (2,8) AND dbo.ProductIdentifiers.IdentifierValue = s.UPC
								LEFT JOIN dbo.ProductBrandAssignments PB  WITH(NOLOCK) on PB.ProductID=dbo.Products.ProductID AND PB.CustomOwnerEntityId= S.SupplierID 
								LEFT JOIN dbo.Brands  WITH(NOLOCK) ON PB.BrandID = dbo.Brands.BrandID  '

	IF (@ProductIdentifierType=8)
		SET @sqlQueryNPShrink = @sqlQueryNPShrink + ' left outer join dbo.ProductIdentifiers PD1  WITH(NOLOCK) on dbo.Products.ProductID = PD1.ProductID and PD1.ProductIdentifierTypeId =8  '

		SET @sqlQueryNPShrink = @sqlQueryNPShrink + ' LEFT OUTER JOIN  dbo.StoresUniqueValues SUV  WITH(NOLOCK) ON S.SupplierID = SUV.SupplierID AND dbo.Stores.StoreID=SUV.StoreID
								LEFT JOIN Warehouses WH  WITH(NOLOCK) ON WH.ChainID=dbo.Chains.ChainID AND WH.WarehouseId=SUV.DistributionCenter 
							    
							    WHERE  1=1 and Cast(S.SaleDateTime as date) between Cast(Stores.ActiveFromDate as date) and Cast(Stores.ActiveLastDate as date)'
	
	IF (@CategoryType=8) 									
		SET @sqlQueryNPShrink = @sqlQueryNPShrink +  ' and ProductIdentifiers.ProductIdentifierTypeId = 8 '
	ELSE IF (@CategoryType=2) 									
		SET @sqlQueryNPShrink = @sqlQueryNPShrink +  ' and ProductIdentifiers.ProductIdentifierTypeId = 2 '
	ELSE
		SET @sqlQueryNPShrink = @sqlQueryNPShrink +  ' and ProductIdentifiers.ProductIdentifierTypeId in (2,8) '
		
    IF(@ChainId <>'-1')
        SET @sqlQueryNPShrink = @sqlQueryNPShrink +  ' and dbo.chains.ChainID=' + @ChainId
 
    IF(@SupplierID <>'-1')
        SET @sqlQueryNPShrink = @sqlQueryNPShrink +  ' and Suppliers.SupplierId=' + @SupplierId
 
    IF(@custom1='')
        SET @sqlQueryNPShrink = @sqlQueryNPShrink + ' and Stores.custom1 is Null'
    ELSE IF(@custom1<>'-1')
        SET @sqlQueryNPShrink = @sqlQueryNPShrink + ' and Stores.custom1=''' + @custom1 + ''''
 
	SET @sqlQueryNPShrink = @sqlQueryNPShrink +  ' and S.TransactionTypeID in (17) '
 
    IF(@CreditType = '0')
        SET @sqlQueryNPShrink = @sqlQueryNPShrink +  ' and S.CreditType is NULL '
   
    ELSE IF(@CreditType <> '-1')                
        SET @sqlQueryNPShrink = @sqlQueryNPShrink +  ' and S.CreditType = ''' + @CreditType + ''''
   
    IF(@BrandId<>'-1')
        SET @sqlQueryNPShrink = @sqlQueryNPShrink +  ' and Brands.BrandId=' + @BrandId
 
    IF(@SupplierInvoiceNumber<>'-1')
        SET @sqlQueryNPShrink = @sqlQueryNPShrink +  ' and S.SupplierInvoiceNumber=''' + @SupplierInvoiceNumber + ''''
       
    IF (convert(date, @TransFromDate  ) > convert(date,'1900-01-01'))
        SET @sqlQueryNPShrink = @sqlQueryNPShrink + ' and S.SaleDateTime  >= ''' + @TransFromDate  + ''''
 
    IF(convert(date, @TransToDate ) > convert(date,'1900-01-01'))
        SET @sqlQueryNPShrink = @sqlQueryNPShrink + ' and S.SaleDateTime  <=''' + @TransToDate  + ''''

    IF(@ProductIdentifierValue<>'')
		BEGIN

			-- 2 = UPC, 3 = Product Name , 7 = Vendor Item Number,8=bipad
			IF (@ProductIdentifierType=2)
				 SET @sqlQueryNPShrink = @sqlQueryNPShrink + ' and ProductIdentifiers.IdentifierValue ' + @ProductIdentifierValue 	
		         
			ELSE IF (@ProductIdentifierType=3)
				SET @sqlQueryNPShrink = @sqlQueryNPShrink + ' and dbo.Products.ProductName ' + @ProductIdentifierValue 	
				
			ELSE IF (@ProductIdentifierType=7)
				SET @sqlQueryNPShrink = @sqlQueryNPShrink + '  and case when dbo.ProductIdentifiers.ProductIdentifierTypeId=2 then S.SupplierItemNumber  else 
				 (select C.SupplierProductID from DataTrue_CustomResultSets.dbo.tmpProductsSuppliersItemsConversion C  with(nolock) 
					where c.ProductId=Products.ProductID and C.SupplierID=Suppliers.SupplierId) end  ' + @ProductIdentifierValue 	
					
			ELSE IF (@ProductIdentifierType=8)
				IF (@ProductIdentifierValue<> '')
					SET @sqlQueryNPShrink = @sqlQueryNPShrink + ' and PD1.BiPad ' + @ProductIdentifierValue 	
		END
    
    
    IF(@StoreIdentifierValue<>'')
        BEGIN
            -- 1 = Store Number, 2 = SBT Number, 3 = Store Name
            IF (@StoreIdentifierType=1)
                SET @sqlQueryNPShrink = @sqlQueryNPShrink + ' and stores.storeidentifier ' + @StoreIdentifierValue 
            ELSE IF (@StoreIdentifierType=2)
                SET @sqlQueryNPShrink = @sqlQueryNPShrink + ' and stores.Custom2 ' + @StoreIdentifierValue 
            ELSE IF (@StoreIdentifierType=3)
                SET @sqlQueryNPShrink = @sqlQueryNPShrink + ' and stores.StoreName ' + @StoreIdentifierValue 
        END
 
    IF(@Others<>'')
    BEGIN
        -- 1 = Distribution Center, 2 = Regional Manager, 3 = Sales Representative
        -- 4 = Supplier Account No, 5 = Driver Name, 6 = Route No
                             
        IF (@OtherOption=1)
			SET @sqlQueryNPShrink = @sqlQueryNPShrink + ' and WH.WarehouseName ' + @Others 
		ELSE IF (@OtherOption=2)
			SET @sqlQueryNPShrink = @sqlQueryNPShrink + ' and SUV.RegionalMgr ' + @Others 
		ELSE IF (@OtherOption=3)
			SET @sqlQueryNPShrink = @sqlQueryNPShrink + ' and SUV.SalesRep ' + @Others 
		ELSE IF (@OtherOption=4)
			SET @sqlQueryNPShrink = @sqlQueryNPShrink + ' and SUV.SupplierAccountNumber ' + @Others 
		ELSE IF (@OtherOption=5)
			SET @sqlQueryNPShrink = @sqlQueryNPShrink + ' and SUV.DriverName ' + @Others 
		ELSE IF (@OtherOption=6)
			SET @sqlQueryNPShrink = @sqlQueryNPShrink + ' and SUV.RouteNumber ' + @Others 
    END
   
   IF(@SupplierIdentifierValue<>'')
		SET @sqlQueryNPShrink = @sqlQueryNPShrink + ' and dbo.Suppliers.SupplierIdentifier like ''%' + @SupplierIdentifierValue + '%'''

   IF(@RetailerIdentifierValue<>'')
		SET @sqlQueryNPShrink = @sqlQueryNPShrink + ' and dbo.Chains.ChainIdentifier like ''%' + @RetailerIdentifierValue + '%'''
    
    SET @sqlQueryNPShrink = @sqlQueryNPShrink + ' group by dbo.Chains.ChainName, dbo.Suppliers.SupplierName, dbo.TransactionTypes.transactiontypeid,Suppliers.SupplierId,
												dbo.Brands.BrandName, dbo.ProductIdentifiers.ProductIdentifierTypeID, dbo.TransactionTypes.TransactionTypeName,'
	 
	 IF(@ViewBy='SaleDate')
		SET @sqlQueryNPShrink = @sqlQueryNPShrink +  ' convert(varchar(10),S.SaleDateTime, 101) , '
     ELSE IF(@ViewBy='WeekEndDate')
		SET @sqlQueryNPShrink = @sqlQueryNPShrink +  ' Convert(varchar(12),dbo.GetWeekEnd(S.SaleDateTime,dbo.Stores.ChainID,dbo.Suppliers.SupplierID),101) , '
						  
	IF (@ShowAggregate<>1)                     
        SET @sqlQueryNPShrink = @sqlQueryNPShrink +  '  WH.WarehouseName, SUV.RegionalMgr, SUV.SalesRep, SUV.supplieraccountnumber,SUV.DriverName, SUV.RouteNumber,'										  
	IF (@ShowAggregate=0)
        SET @sqlQueryNPShrink = @sqlQueryNPShrink +  ' dbo.Stores.custom1, dbo.Stores.StoreName,S.rulecost, S.Promoallowance,dbo.Stores.Custom2, dbo.Stores.StoreIdentifier, 
														isnull(S.SupplierInvoiceNumber,''''),WH.WarehouseName, SUV.RegionalMgr, SUV.SalesRep, SUV.supplieraccountnumber, SUV.DriverName, 
														SUV.RouteNumber, dbo.Products.ProductName, Products.ProductID, dbo.ProductIdentifiers.IdentifierValue, s.RuleRetail,  
														dbo.ProductIdentifiers.ProductIdentifierTypeId, S.SupplierItemNumber '
     
    ELSE IF (@ShowAggregate=1)
        SET @sqlQueryNPShrink = @sqlQueryNPShrink +  ' dbo.Products.ProductName, Products.ProductID, 
													  dbo.ProductIdentifiers.IdentifierValue, 
													  dbo.ProductIdentifiers.ProductIdentifierTypeId, S.SupplierItemNumber '
	ELSE IF (@ShowAggregate=2)
        SET @sqlQueryNPShrink = @sqlQueryNPShrink +  ' dbo.Stores.custom1, dbo.Stores.StoreName,
													  dbo.Stores.Custom2,  dbo.Stores.StoreIdentifier, 
													  isnull(S.SupplierInvoiceNumber,''''),WH.WarehouseName, SUV.RegionalMgr, SUV.SalesRep,
													  SUV.supplieraccountnumber, SUV.DriverName, SUV.RouteNumber '         
                          										  
	IF (EXISTS(Select @ActivityType Where @ActivityType LIKE '%21,8,14%'))
             SET @sqlQueryNPShrink = @sqlQueryNPShrink +  ' , S.CreditType '
    	
    IF (EXISTS(Select @ActivityType Where @ActivityType LIKE '%21,8,14%') or EXISTS(Select @ActivityType Where @ActivityType LIKE '%2,6,7,16%') or EXISTS(Select @ActivityType Where @ActivityType LIKE '%5,9,20%'))
			 SET @sqlQueryNPShrink = @sqlQueryNPShrink +  ' , dbo.Stores.Custom4 '
    
    /************** Query For Newspaper Shrink End(AS per discussion on FB case 21073) *******************/
    
    
	IF (@ActivityType='17,18,19,22,23' AND NOT EXISTS(SELECT C.ChainID FROM chains_migration INNER JOIN Chains C ON C.ChainIdentifier=chains_migration.chainid WHERE C.ChainID=@ChainId))
		BEGIN
			--Print 1
			--PRINT(@sqlQueryShrink);
			EXEC(@sqlQueryShrink);
		END
	ELSE IF (@ActivityType='-999')
		BEGIN
			--Print 2
			--PRINT(@sqlQueryNPShrink);
			EXEC(@sqlQueryNPShrink);
		END
	ELSE IF(@ActivityType = '17,18,19,22,23,-999' OR @ActivityType = '-999,17,18,19,22,23' )
		BEGIN
			--Print 3
			--PRINT(@sqlQueryShrink) PRINT(' UNION ALL ')  PRINT(@sqlQueryNPShrink );
			EXEC(@sqlQueryShrink + ' UNION ALL ' + @sqlQueryNPShrink );
		END	
	ELSE IF(NOT EXISTS(SELECT @ActivityType WHERE @ActivityType LIKE '%17,18,19,22,23%') AND NOT EXISTS(SELECT @ActivityType WHERE @ActivityType LIKE '%-999%'))
		BEGIN
			--Print 4
			Print(@sqlQuery);
			EXEC(@sqlQuery);
		END
	ELSE IF(EXISTS(SELECT @ActivityType WHERE @ActivityType LIKE '%17,18,19,22,23%') AND NOT EXISTS(SELECT @ActivityType WHERE @ActivityType LIKE '%-999%'))
		BEGIN
			--Print 5
			--PRINT(@sqlQueryShrink) PRINT (' UNION ALL ')  PRINT (@sqlQuery );
			EXEC(@sqlQueryShrink + ' UNION ALL ' +  @sqlQuery );
		END
	ELSE IF(NOT EXISTS(SELECT @ActivityType WHERE @ActivityType LIKE '%17,18,19,22,23%') AND EXISTS(SELECT @ActivityType WHERE @ActivityType LIKE '%-999%'))
		BEGIN
			--Print 6
			--PRINT(@sqlQueryNPShrink) PRINT(' UNION ALL ') PRINT(@sqlQuery );
			EXEC(@sqlQueryNPShrink + ' UNION ALL ' + @sqlQuery );
		END
	ELSE IF(EXISTS(SELECT @ActivityType WHERE @ActivityType LIKE '%17,18,19,22,23%') AND EXISTS(SELECT @ActivityType WHERE @ActivityType LIKE '%-999%'))
		BEGIN
			--Print 7
			--PRINT(@sqlQueryShrink) PRINT(' UNION ALL ') PRINT  (@sqlQueryNPShrink) PRINT (' UNION ALL ') PRINT (@sqlQuery );
			EXEC(@sqlQueryShrink + ' UNION ALL ' +  @sqlQueryNPShrink + ' UNION ALL ' + @sqlQuery );
		END	
	ELSE
		BEGIN
			--Print 8
			--PRINT(@sqlQuery);
			EXEC(@sqlQuery);
		END
End
GO
