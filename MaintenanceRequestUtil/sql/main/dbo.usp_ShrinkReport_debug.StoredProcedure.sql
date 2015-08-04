USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_ShrinkReport_debug]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec [usp_ShrinkReport_debug] '40562','40393','Albertsons - ACME','05/16/2013','1','2','','1','','1','','Unsettled'
CREATE procedure [dbo].[usp_ShrinkReport_debug]
 @SupplierId varchar(5),
 @ChainID varchar(5),
 @Custom1 varchar(255),
 @LastInventoryDate varchar(50),
 @ItemLevel int,
 @ProductIdentifierType int,
 @ProductIdentifierValue varchar(50),
 @StoreIdentifierType int,
 @StoreIdentifierValue varchar(50),
 @OtherOption int,
 @Others varchar(50),
 @Status varchar(20)
 as
Begin
 Declare @sqlQuery varchar(8000), @sqlDate varchar(2000), @sqlCriteria varchar(4000), @sqlGroupBY varchar(2000)

IF OBJECT_ID('tempdb..#tmpShrinkRecords') IS NOT NULL  
BEGIN
    DROP TABLE #tmpShrinkRecords
END
CREATE TABLE #tmpShrinkRecords(
	[SupplierId] [int] NOT NULL,
	[SupplierName] [nvarchar](50) NULL,
	[ChainName] [nvarchar](50) NULL,
	[StoreNo] [nvarchar](50) NULL,
	[supplieracctno] [nvarchar](50) NULL,
	[StoreID] [int] NOT NULL,
	[ChainID] [int] NOT NULL,
	[ProductId] [int] NOT NULL,
	[Banner] [nvarchar](50) NULL,
	[LastInventoryCountDate] [datetime] NULL,
	[LastSettlementDate] [datetime] NULL,
	[GLCode] [nvarchar](50) NULL,
	[UPC] [nvarchar](50) NULL,
	[SupplierUniqueProductID] [nvarchar](50) NULL,
	[BI Count] [money] NULL,
	[BI$] [money] NULL,
	[Net Deliveries] [money] NULL,
	[Net Deliveries$] [money] NULL,
	[Net POS] [money] NULL,
	[POS$] [money] NULL,
	[Expected EI] [money] NULL,
	[Expected EI$] [money] NULL,
	[LastCountQty] [money] NULL,
	[LastCount$] [money] NULL,
	[ShrinkUnits] [money] NULL,
	[NetUnitCostLastCountDate] [money] NULL,
	[Shrink$] [money] NULL,
	[SharedShrinkUnits] [money] NULL,
	[SharedShrink$] [money] NULL,
	[WeightedAvgCost] [money] NULL,
	[Status] [varchar](9) NULL,
	[NewStatus] [varchar](8) NOT NULL
) 

		Select SupplierId, RetailerId, StoreId, ProductId, max(IR1.PhysicalInventoryDate) as MaxDate 
		into #tmpMaxDate
		from InventorySettlementRequests IR1
		where ir1.Settle ='y' and supplierId =@SupplierId
		Group by  SupplierId, RetailerId, StoreId, ProductId

		--clear any records from the Daily Fact table, that were apporved on the same date as Today!
		delete 
		i
		from InventoryReport_New_FactTable_debug i
		inner join (select * from InventorySettlementRequests i where cast(i.ApprovedDate as date) = cast(GETDATE() as date)) t 
		on t.supplierId =i.SupplierID and t.StoreID =i.StoreID  
		and t.ProductID =i.ProductID  and t.PhysicalInventoryDate =i.LastInventoryCountDate 
		where i.SupplierId=@SupplierId
		
		if(@Status='Unsettled')
			Begin
				--Taking all records from the Fact Table, that does not exist as Pending.        
				set @sqlQuery = 'Insert into #tmpShrinkRecords
						select MR.SupplierId, MR.SupplierName, MR.ChainName,MR.StoreNo,MR.supplieracctno,MR.StoreID, MR.ChainID,MR.ProductId,
								MR.Banner, MR.[LastInventoryCountDate],MR.[LastSettlementDate], MR.GLCode, MR.UPC ,  MR.SupplierUniqueProductID,
								MR.[BI Count], MR.[BI$], MR.[Net Deliveries], MR.[Net Deliveries$],MR.[Net POS], MR.[POS$],
								MR.[Expected EI], MR.[Expected EI$], MR.[LastCountQty], MR.[LastCount$], MR.[ShrinkUnits],
								MR.NetUnitCostLastCountDate, MR.[Shrink$], MR.[SharedShrinkUnits], IR.[SharedShrink$], MR.WeightedAvgCost,
								''Unsettled'' as [Status],
								''Settle'' as [NewStatus]
						from [InventoryReport_New_FactTable_debug] as MR
						inner join Products P on P.ProductId=MR.ProductId
						inner join SupplierBanners SB on SB.SupplierId = MR.SupplierId and SB.Status=''Active'' and SB.Banner=MR.Banner
						Left Join InventorySettlementRequests IR on IR.SupplierId=MR.SupplierId and IR.retailerId=MR.ChainID
						and IR.StoreID=MR.StoreID and MR.ProductID=IR.ProductID and IR.Settle = (''Pending'') and IR.PhysicalInventoryDate =MR.LastInventoryCountDate
						Where IR.supplierId  is null and MR.SupplierID=' + @SupplierId + ' and MR.ChainID=' + @ChainID
				
				if(@custom1<>'-1')
					set @sqlQuery = @sqlQuery + ' and MR.Banner=''' + @custom1 + ''''

				if(@ProductIdentifierValue<>'')
					begin
						-- 2 = UPC, 3 = Product Name 
						if (@ProductIdentifierType=2)
							 set @sqlQuery = @sqlQuery + ' and MR.UPC like ''%' + @ProductIdentifierValue + '%'''
						     
						else if (@ProductIdentifierType=3)
							set @sqlQuery = @sqlQuery + ' and P.ProductName like ''%' + @ProductIdentifierValue + '%'''
							
						else if (@ProductIdentifierType=10)
							set @sqlQuery = @sqlQuery + ' and MR.GLCode like ''%' + @ProductIdentifierValue + '%'''
					end
			End
		if(@Status='Pending')
			Begin
				-- Taking all records from the Fact Table, that are already pending in the InventorySettlmentTable (due to prior settlement requests that were not yet approved), and marking them as Pending as well.
       
				set @sqlQuery = ' Insert into #tmpShrinkRecords
								select IR.SupplierId, S.SupplierName, C.ChainName,IR.StoreNumber, IR.SupplierAcctNo, IR.StoreID, C.ChainID, IR.ProductId,
						IR.Banner, IR.[PhysicalInventoryDate],IR.[PriorInventoryCountDate],IR.GLCode, IR.UPC, IR.SupplierUniqueProductID,
						IR.[BI Count], IR.[BI$], IR.[Net Deliveries], IR.[Net Deliveries$],IR.[Net POS], IR.[POS$],
						(IR.[BI Count]+IR.[Net Deliveries]-IR.[Net POS]) as  [Expected EI],
						(IR.BI$+IR.[Net Deliveries$]-IR.[POS$]) as [Expected EI$], IR.[LastCountQty], IR.[LastCount$], IR.[ShrinkUnits],
						IR.NetUnitCostLastCountDate, IR.[Shrink$], IR.[SharedShrinkUnits], IR.[SharedShrink$], IR.WeightedAvgCost,   
						''Pending'' as [Status], ''Unsettle'' as [NewStatus]

					from InventorySettlementRequests as IR
					Inner Join Suppliers S on S.SupplierID=IR.supplierId
					Inner Join Chains C on C.ChainID=IR.retailerId
					inner join SupplierBanners SB on SB.SupplierId = S.SupplierId and SB.Status=''Active'' 
					and SB.Banner=IR.Banner where 1 =1 and IR.Settle=''Pending'' and IR.SupplierID=' + @SupplierId + ' and IR.RetailerId=' + @ChainID

				if(@custom1<>'-1')
					set @sqlQuery = @sqlQuery + ' and IR.Banner=''' + @custom1 + ''''
		     
				if(@ProductIdentifierValue<>'')
				 begin
					-- 2 = UPC, 3 = Product Name , 10 = GL Code
					if (@ProductIdentifierType=2)
						 set @sqlQuery = @sqlQuery + ' and IR.UPC like ''%' + @ProductIdentifierValue + '%'''
				         
					else if (@ProductIdentifierType=3)
						set @sqlQuery = @sqlQuery + ' and P.ProductName like ''%' + @ProductIdentifierValue + '%'''
					
					else if (@ProductIdentifierType=10)
						set @sqlQuery = @sqlQuery + ' and IR.GLCode like ''%' + @ProductIdentifierValue + '%'''
				 end
				 
				 if (convert(date, @LastInventoryDate) > convert(date,'1900-01-01'))    
				   set @sqlQuery = @sqlQuery + ' and IR.PhysicalInventoryDate< =''' + @LastInventoryDate  + ''''
			End
		if(@Status='Approved' or @Status='Rejected')
			Begin	
				--Taking all the records from InventorySettlmentRequests Tablethat are NOT Pending (hence, Approved or rejected), prior to the date the user entered.
				
				set @sqlQuery =  'Insert into #tmpShrinkRecords
						select IR.SupplierId, S.SupplierName, C.ChainName,IR.StoreNumber, IR.SupplierAcctNo, IR.StoreID, C.ChainID, IR.ProductId,
						IR.Banner, IR.[PhysicalInventoryDate],IR.[PriorInventoryCountDate],IR.GLCode, IR.UPC, IR.SupplierUniqueProductID,
						IR.[BI Count], IR.[BI$], IR.[Net Deliveries], IR.[Net Deliveries$],IR.[Net POS], IR.[POS$],
						(IR.[BI Count]+IR.[Net Deliveries]-IR.[Net POS]) as  [Expected EI],
						(IR.BI$+IR.[Net Deliveries$]-IR.[POS$]) as [Expected EI$], IR.[LastCountQty], IR.[LastCount$], IR.[ShrinkUnits],
						IR.NetUnitCostLastCountDate, IR.[Shrink$], IR.[SharedShrinkUnits], IR.[SharedShrink$], IR.WeightedAvgCost,   
						case when IR.Settle=''Y'' then ''Approved''
							 when IR.Settle=''N'' then ''Rejected''
						end as [Status], '''' as [NewStatus]

					from InventorySettlementRequests as IR
					Inner Join Suppliers S on S.SupplierID=IR.supplierId
					Inner Join Chains C on C.ChainID=IR.retailerId
					inner join SupplierBanners SB on SB.SupplierId = S.SupplierId and SB.Status=''Active'' 
					and SB.Banner=IR.Banner where 1 =1 and (IR.Settle=''Y'' or IR.Settle=''N'') and IR.SupplierID=' + @SupplierId +  ' and IR.retailerId=' + @ChainID
		         
		         if(@custom1<>'-1')
					set @sqlQuery = @sqlQuery + ' and IR.Banner=''' + @custom1 + ''''
					
				 if(@ProductIdentifierValue<>'')
				 begin
					-- 2 = UPC, 3 = Product Name 
					if (@ProductIdentifierType=2)
						 set @sqlQuery = @sqlQuery + ' and IR.UPC like ''%' + @ProductIdentifierValue + '%'''
					
					else if (@ProductIdentifierType=10)
						set @sqlQuery = @sqlQuery + ' and IR.GLCode like ''%' + @ProductIdentifierValue + '%'''
												 
				 end
				 
				if (convert(date, @LastInventoryDate) > convert(date,'1900-01-01'))    
				   set @sqlQuery = @sqlQuery + ' and IR.PhysicalInventoryDate< =''' + @LastInventoryDate  + ''''
			End
		
        exec(@sqlQuery);
                            
        set @sqlQuery = 'Select MR.SupplierId,MR.SupplierName as [Supplier Name], MR.ChainName as [Retailer Name],
						  MR.Banner, convert(date,MR.[LastInventoryCountDate],101) as [Last Count Date],
						  convert(date,MR.[LastSettlementDate],101) as [BI Date],'
        if (@ItemLevel>0)
            set @sqlQuery = @sqlQuery +  ' CAST(MR.StoreNo AS VARCHAR) as [Store Number], MR.SupplierAcctNo as [Supplier Acct Number],'
        else
            set @sqlQuery = @sqlQuery +  ' '''' as [Store Number], '''' as [Supplier Acct Number],  '
       
        if (@ItemLevel=2)
			begin
				--if(@SupplierId=40559)					
					set @sqlQuery = @sqlQuery +  ' cast(MR.GLCode as varchar) as [GL Code],'
					
				set @sqlQuery = @sqlQuery +  ' cast(MR.UPC as varchar) as UPC,'
				
				if(@SupplierId=40561)					
					set @sqlQuery = @sqlQuery + '(Select IdentifierValue from  ProductIdentifiers PD where PD.ProductId=MR.ProductId and ProductIdentifierTypeID=3) as [Supplier Product Code],'
				
			end
        else
            set @sqlQuery = @sqlQuery +  ' '''' as UPC, '''' as [Supplier Product Code],'
      
      
        set @sqlQuery = @sqlQuery +  '
            sum(MR.[BI Count]) as [BI Count],
            sum(cast(MR.[BI$] as numeric(10,4))) as [BI$],
            sum(MR.[Net Deliveries]) as [Total Deliveries],
            sum(cast(MR.[Net Deliveries$] as numeric(10,4))) as [Total Deliveries$],
            sum(MR.[Net POS]) as [Total POS],
            sum(cast(MR.[POS$] as numeric(10,4))) as [Total POS$],
            sum(MR.[Expected EI]) as [Expected EI Count],
            sum(cast(MR.[Expected EI$] as numeric(10,4))) as [Expected EI$],
            sum(MR.[LastCountQty]) as [Last Count],
            sum(cast(MR.[LastCount$] as numeric(10,4))) as [Last Count$],
            sum(MR.[ShrinkUnits])as [Shrink Units Aggregated Count],
            sum(cast(MR.[Shrink$] as numeric(10,4))) as [Shrink$ WeightedAvg],
            sum(MR.[SharedShrink$]) as [Shared Shrink$ (WeightedAvg)],
            case when sum(MR.[BI$] + MR.[Net Deliveries$]) >0 then
                cast((sum(cast(MR.[Shrink$] as numeric(10,4))))/ sum(MR.[BI$] + MR.[Net Deliveries$]) as numeric(10,4))
                 else 0
            end  as [Shrink as % of (BI$+Delivery$)],
        
            case when sum(MR.[POS$]) >0 then
                cast((sum(cast(MR.[Shrink$] as numeric(10,4))))/ sum(MR.[POS$]) as numeric(10,4))
                 else 0
            end  as [Shrink as % of POS$], sum(MR.SharedShrinkUnits) as [Shared Shrink Units],'
        
        if (@ItemLevel>0)
            set @sqlQuery = @sqlQuery +  ' SUV.DistributionCenter as [Distribution Center], SUV.RegionalMgr as [Regional Manager], SUV.SalesRep as [Sales Representative],
										   SUV.DriverName As Driver, cast(SUV.RouteNumber as varchar) as RouteNo,'
        else
            set @sqlQuery = @sqlQuery +  ' '''' as [Distribution Center], '''' as [Regional Manager], '''' as [Sales Representative], '''' as Driver, '''' as RouteNo, '
            
        set @sqlQuery = @sqlQuery +  ' MR.[Status],MR.[NewStatus]        
									   From #tmpShrinkRecords as MR '
      
        if (convert(date, @LastInventoryDate) > convert(date,'1900-01-01'))    
        Begin
        set @sqlDate =  ' inner join (select  i.StoreID,max(i.LastInventoryCountDate) as MaxDate,i.SupplierID, i.upc
                    from InventoryReport_New_FactTable_debug i
                    where i.SupplierID=' + @SupplierId + ' and i.LastInventoryCountDate <=''' + @LastInventoryDate  + '''
                    group by i.StoreID,i.SupplierID, i.upc) t
                    on t.UPC=MR.UPC and t.StoreID =MR.StoreID and t.MaxDate=MR.LastInventoryCountDate
                    and t.SupplierID =MR.SupplierID '
        end
       
        set @sqlCriteria =  ' LEFT OUTER JOIN dbo.StoresUniqueValues SUV ON MR.SupplierID = SUV.SupplierID
                    AND SUV.StoreID = MR.StoreID where  1=1 '
    
        if(@SupplierId <>'-1')
            set @sqlCriteria = @sqlCriteria +  ' and MR.SupplierID=' + @SupplierId

        if(@ChainID <>'-1')
            set @sqlCriteria = @sqlCriteria +  ' and MR.ChainID=' + @ChainID

        if(@custom1<>'-1')
            set @sqlCriteria = @sqlCriteria + ' and MR.Banner=''' + @custom1 + ''''
     
        if(@StoreIdentifierValue<>'')
        begin
    
            if (@StoreIdentifierType=1)
                set @sqlCriteria = @sqlCriteria + ' and MR.StoreNo like ''%' + @StoreIdentifierValue + '%'''
            else if (@StoreIdentifierType=2)
                set @sqlCriteria = @sqlCriteria + ' and SUV.SBTNumber like ''%' + @StoreIdentifierValue + '%'''
            else if (@StoreIdentifierType=3)
                set @sqlCriteria = @sqlCriteria + ' and STR.StoreName like ''%' + @StoreIdentifierValue + '%'''
        end
     
       
        if(@Others<>'')
        begin
            -- 1 = Distribution Center, 2 = Regional Manager, 3 = Sales Representative
            -- 4 = Supplier Account No, 5 = Driver Name, 6 = Route No
                                 
            if (@OtherOption=1)
				set @sqlCriteria = @sqlCriteria + ' and SUV.DistributionCenter like ''%' + @Others + '%'''
			else if (@OtherOption=2)
				set @sqlCriteria = @sqlCriteria + ' and SUV.RegionalMgr like ''%' + @Others + '%'''
			else if (@OtherOption=3)
				set @sqlCriteria = @sqlCriteria + ' and SUV.SalesRep like ''%' + @Others + '%'''
			else if (@OtherOption=4)
				set @sqlCriteria = @sqlCriteria + ' and SUV.SupplierAccountNumber like ''%' + @Others + '%'''
			else if (@OtherOption=5)
				set @sqlCriteria = @sqlCriteria + ' and SUV.DriverName like ''%' + @Others + '%'''
			else if (@OtherOption=6)
				set @sqlCriteria = @sqlCriteria + ' and SUV.RouteNumber like ''%' + @Others + '%'''

        end

        if(@Status<>'-1')
            set @sqlCriteria = @sqlCriteria + ' and MR.Status =''' + @Status + ''''
           
        set @sqlGroupBY =  ' Group by MR.SupplierId, MR.SupplierName, MR.ChainName, MR.Banner,
                                      MR.[LastInventoryCountDate],MR.[LastSettlementDate], MR.Status, MR.NewStatus '
       
        if (@ItemLevel>0)
            set @sqlGroupBY = @sqlGroupBY +  ', MR.StoreNo, MR.SupplierAcctNo,SUV.DistributionCenter, SUV.RegionalMgr,
												SUV.SalesRep, SUV.DriverName, SUV.RouteNumber '
       
        if (@ItemLevel=2)
            set @sqlGroupBY = @sqlGroupBY +  ',MR.GLCode, MR.UPC, MR.ProductId '
        
        if(@Status='Unsettled' or @Status='Pending')   
			set @sqlQuery=@sqlQuery + @sqlDate + @sqlCriteria + ' and MR.[BI Count] IS Not NULL ' + @sqlGroupBY 
		else
	        set @sqlQuery= @sqlQuery +  ' inner join (select t.supplierid, t.StoreID,t.ProductID ,t.LastSettlementDate as BIDate ,max(t.LastInventoryCountDate ) as LastCountDate from #tmpShrinkRecords  t
														group by t.Status, t.supplierid, t.StoreID,t.ProductID ,t.LastSettlementDate ) t 
										  on t.supplierId=MR.SupplierID and t.StoreID=MR.StoreID and t.ProductID=MR.ProductID  and t.LastCountDate = MR.LastInventoryCountDate ' + @sqlCriteria + ' and MR.[LastSettlementDate] IS Not NULL' +  @sqlGroupBY
		exec (@sqlQuery);
                 
		IF OBJECT_ID('tempdb..#tmpShrinkRecords') IS NOT NULL  
		BEGIN
			DROP TABLE #tmpShrinkRecords
		END                                   
       
End
GO
