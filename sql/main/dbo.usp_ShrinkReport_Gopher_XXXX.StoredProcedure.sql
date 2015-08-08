USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_ShrinkReport_Gopher_XXXX]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_ShrinkReport_Gopher_XXXX]
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
 Declare @sqlQuery varchar(8000)
begin try
    Drop Table [@tmpShrinkSettlement]
end try
begin catch
end catch

        set @sqlQuery = 'select MR.SupplierId, MR.SupplierName, MR.ChainName,MR.StoreNo,MR.supplieracctno,MR.StoreID, MR.ChainID,
								MR.Banner, MR.[LastInventoryCountDate],MR.[LastSettlementDate],MR.UPC , MR.SupplierUniqueProductID,
								MR.[BI Count], MR.[BI$], MR.[Net Deliveries], MR.[Net Deliveries$],MR.[Net POS], MR.[POS$],
								MR.[Expected EI], MR.[Expected EI$], MR.[LastCountQty], MR.[LastCount$], MR.[ShrinkUnits],
								MR.NetUnitCostLastCountDate, MR.[Shrink$], MR.[SharedShrinkUnits], MR.WeightedAvgCost,
								case when IR.Settle is NULL then ''Unsettled''
									when IR.Settle=''Pending'' then ''Pending''
									when IR.Settle=''Y'' then ''Approved''
									when IR.Settle=''N'' then ''Rejected''
								end as [Status],
								case when IR.Settle is NULL then ''Settle''
									when IR.Settle=''Pending'' then ''Unsettle''
									else ''''
								end as [NewStatus]
						into [@tmpShrinkSettlement]
						from [InventoryReport_New_FactTable_Gopher] as MR
						inner join Products P on P.ProductId=MR.ProductId
						Left Join InventorySettlementRequests IR on IR.SupplierId=MR.SupplierId and IR.retailerId=MR.ChainID
						and IR.StoreID=MR.StoreID and MR.ProductID=IR.ProductID and IR.Settle =''Pending''
						where IR.supplierId  is null '
						
		if(@SupplierId <>'-1')
            set @sqlQuery = @sqlQuery +  ' and MR.SupplierID=' + @SupplierId

        if(@ChainID <>'-1')
            set @sqlQuery = @sqlQuery +  ' and MR.ChainID=' + @ChainID

        if(@custom1='')
            set @sqlQuery = @sqlQuery + ' and MR.Banner is Null'

        else if(@custom1<>'-1')
            set @sqlQuery = @sqlQuery + ' and MR.Banner=''' + @custom1 + ''''
     
		 if(@ProductIdentifierValue<>'')
		 begin
			-- 2 = UPC, 3 = Product Name 
			if (@ProductIdentifierType=2)
				 set @sqlQuery = @sqlQuery + ' and MR.UPC like ''%' + @ProductIdentifierValue + '%'''
		         
			else if (@ProductIdentifierType=3)
				set @sqlQuery = @sqlQuery + ' and P.ProductName like ''%' + @ProductIdentifierValue + '%'''
		 end

       
        set @sqlQuery = @sqlQuery + ' union all '
       
        set @sqlQuery = @sqlQuery + ' select MR.SupplierId, MR.SupplierName, MR.ChainName,MR.StoreNo,MR.supplieracctno,MR.StoreID, MR.ChainID,
										MR.Banner, MR.[LastInventoryCountDate],MR.[LastSettlementDate],MR.UPC , MR.SupplierUniqueProductID,
										MR.[BI Count], MR.[BI$], MR.[Net Deliveries], MR.[Net Deliveries$],MR.[Net POS], MR.[POS$],
										MR.[Expected EI], MR.[Expected EI$], MR.[LastCountQty], MR.[LastCount$], MR.[ShrinkUnits],
										MR.NetUnitCostLastCountDate, MR.[Shrink$], MR.[SharedShrinkUnits], MR.WeightedAvgCost,
										''Unsettled'' as [Status], ''Settle'' as [NewStatus]

								from [InventoryReport_New_FactTable_Gopher] as MR
								inner join Products P on P.ProductId=MR.ProductId
								inner Join InventorySettlementRequests IR on IR.SupplierId=MR.SupplierId and IR.retailerId=MR.ChainID
								and IR.StoreID=MR.StoreID and MR.ProductID=IR.ProductID where MR.LastInventoryCountDate >
                                            (Select max(IR1.PhysicalInventoryDate) from InventorySettlementRequests IR1
                                             where IR1.SupplierId=MR.SupplierId and IR1.retailerId=MR.ChainID
                                             and IR1.StoreID=MR.StoreID and MR.ProductID=IR1.ProductID)
                                             and IR.Settle=''Pending'''
       
        if(@SupplierId <>'-1')
            set @sqlQuery = @sqlQuery +  ' and MR.SupplierID=' + @SupplierId

        if(@ChainID <>'-1')
            set @sqlQuery = @sqlQuery +  ' and MR.ChainID=' + @ChainID

        if(@custom1='')
            set @sqlQuery = @sqlQuery + ' and MR.Banner is Null'

        else if(@custom1<>'-1')
            set @sqlQuery = @sqlQuery + ' and MR.Banner=''' + @custom1 + ''''
     
        if(@ProductIdentifierValue<>'')
		 begin
			-- 2 = UPC, 3 = Product Name 
			if (@ProductIdentifierType=2)
				 set @sqlQuery = @sqlQuery + ' and MR.UPC like ''%' + @ProductIdentifierValue + '%'''
		         
			else if (@ProductIdentifierType=3)
				set @sqlQuery = @sqlQuery + ' and P.ProductName like ''%' + @ProductIdentifierValue + '%'''
		 end
       
        set @sqlQuery = @sqlQuery + ' union all '
     
        set @sqlQuery = @sqlQuery + 'select IR.SupplierId, S.SupplierName, C.ChainName,ST.StoreIdentifier,IR.SupplierAcctNo,ST.StoreID, C.ChainID,
                St.Custom1, IR.[PhysicalInventoryDate],IR.[PriorInventoryCountDate],IR.UPC, IR.SupplierUniqueProductID,
                IR.[BI Count], IR.[BI$], IR.[Net Deliveries], IR.[Net Deliveries$],IR.[Net POS], IR.[POS$],
                (IR.[BI Count]+IR.[Net Deliveries]-IR.[Net POS]) as  [Expected EI],
                (IR.BI$+IR.[Net Deliveries$]-IR.[POS$]) as [Expected EI$], IR.[LastCountQty], IR.[LastCount$], IR.[ShrinkUnits],
                IR.NetUnitCostLastCountDate, IR.[Shrink$], IR.[SharedShrinkUnits], IR.WeightedAvgCost,   
                        case when IR.Settle is NULL then ''Unsettled''
                            when IR.Settle=''Pending'' then ''Pending''
                            when IR.Settle=''Y'' then ''Approved''
                            when IR.Settle=''N'' then ''Rejected''
                        end as [Status],
                        case when IR.Settle is NULL then ''Settle''
                            when IR.Settle=''Pending'' then ''Unsettle''
                            else ''''
                        end as [NewStatus]
           
            from InventorySettlementRequests as IR
            Inner Join Suppliers S on S.SupplierID=IR.supplierId
            Inner Join Chains C on C.ChainID=IR.retailerId
            Inner Join Stores ST on ST.StoreID=IR.StoreID and ST.ActiveStatus=''Active'''
        
        if(@SupplierId <>'-1')
            set @sqlQuery = @sqlQuery +  ' and IR.SupplierID=' + @SupplierId

        if(@ChainID <>'-1')
            set @sqlQuery = @sqlQuery +  ' and IR.retailerId=' + @ChainID
         
         if(@ProductIdentifierValue<>'')
		 begin
			-- 2 = UPC, 3 = Product Name 
			if (@ProductIdentifierType=2)
				 set @sqlQuery = @sqlQuery + ' and IR.UPC like ''%' + @ProductIdentifierValue + '%'''
		 end
		 
        exec(@sqlQuery);
             
        set @sqlQuery = 'Select MR.SupplierName as [Supplier Name], MR.ChainName as [Retailer Name],
                  MR.Banner, '
       
        if (@ItemLevel=2)
            set @sqlQuery = @sqlQuery +  '  cast(MR.UPC as varchar) as UPC,'
        else
            set @sqlQuery = @sqlQuery +  ' '''' as UPC, '
      
      
        set @sqlQuery = @sqlQuery +  ' CAST(convert(char(10),MR.[LastInventoryCountDate],101) AS VARCHAR) as [Last Count Date],
			sum(MR.[LastCountQty]) as [Last Count],
            cast(sum(MR.[LastCount$]) as numeric(10,2)) as [Last Count$],
            cast(convert(varchar(10),MR.[LastSettlementDate],101) as varchar) as [BI Date],
            sum(MR.[BI Count]) as [BI Count],
            cast(sum(MR.[BI$]) as numeric(10,2)) as [BI$],
            sum(MR.[Net Deliveries]) as [Total Net Deliveries],
            cast(sum(MR.[Net Deliveries$]) as numeric(10,2)) as [Total Net Deliveries$],
            sum(MR.[Net POS]) as [Total POS],
            cast(sum(MR.[POS$]) as numeric(10,2)) as [Total POS$],
            sum(MR.[Expected EI]) as [Expected EI Count],
            cast(sum(MR.[Expected EI$]) as numeric(10,2)) as [Expected EI$],'
            
        if (@ItemLevel>0)
            set @sqlQuery = @sqlQuery +  ' CAST(MR.StoreNo AS VARCHAR) as [Store Number], MR.SupplierAcctNo as [Supplier Acct Number],'
        else
            set @sqlQuery = @sqlQuery +  ' '''' as [Store Number], '''' as [Supplier Acct Number],  '
            
        set @sqlQuery = @sqlQuery +  ' SUV.DistributionCenter as [Distribution Center], SUV.RegionalMgr as [Regional Manager], SUV.SalesRep as [Sales Representative],
            SUV.DriverName As Driver, cast(SUV.RouteNumber as varchar) as RouteNo
            From [@tmpShrinkSettlement] as MR '
      
        if (convert(date, @LastInventoryDate) > convert(date,'1900-01-01'))    
        Begin
        set @sqlQuery = @sqlQuery + ' inner join (select  i.StoreID,max(i.LastInventoryCountDate) as MaxDate,i.SupplierID, i.upc
                    from InventoryReport_New_FactTable_Gopher i
                    where i.LastInventoryCountDate <=''' + @LastInventoryDate  + '''
                    group by i.StoreID,i.SupplierID, i.upc) t
                    on t.UPC=MR.UPC and t.StoreID =MR.StoreID and t.MaxDate=MR.LastInventoryCountDate and t.SupplierID =MR.SupplierID '
        end
       
        set @sqlQuery = @sqlQuery + ' LEFT OUTER JOIN dbo.StoresUniqueValues SUV ON MR.SupplierID = SUV.SupplierID
                    AND SUV.StoreID = MR.StoreID where  1=1 '
    
        if(@SupplierId <>'-1')
            set @sqlQuery = @sqlQuery +  ' and MR.SupplierID=' + @SupplierId

        if(@ChainID <>'-1')
            set @sqlQuery = @sqlQuery +  ' and MR.ChainID=' + @ChainID

        if(@custom1='')
            set @sqlQuery = @sqlQuery + ' and MR.Banner is Null'

        else if(@custom1<>'-1')
            set @sqlQuery = @sqlQuery + ' and MR.Banner=''' + @custom1 + ''''
     
       
        if(@StoreIdentifierValue<>'')
        begin
    
            if (@StoreIdentifierType=1)
                set @sqlQuery = @sqlQuery + ' and MR.StoreNo like ''%' + @StoreIdentifierValue + '%'''
            else if (@StoreIdentifierType=2)
                set @sqlQuery = @sqlQuery + ' and SUV.SBTNumber like ''%' + @StoreIdentifierValue + '%'''
            else if (@StoreIdentifierType=3)
                set @sqlQuery = @sqlQuery + ' and STR.StoreName like ''%' + @StoreIdentifierValue + '%'''
        end
     
       
        if(@Others<>'')
        begin
            -- 1 = Distribution Center, 2 = Regional Manager, 3 = Sales Representative
            -- 4 = Supplier Account No, 5 = Driver Name, 6 = Route No
                                 
            if (@OtherOption=1)
				set @sqlQuery = @sqlQuery + ' and SUV.DistributionCenter like ''%' + @Others + '%'''
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

        if(@Status<>'-1')
            set @sqlQuery = @sqlQuery + ' and MR.Status =''' + @Status + ''''
           
        set @sqlQuery = @sqlQuery +  ' Group by MR.SupplierName, MR.ChainName,
                                        SUV.DistributionCenter, SUV.RegionalMgr,
                                        SUV.SalesRep, SUV.DriverName, SUV.RouteNumber, MR.Banner,
                                        MR.[LastInventoryCountDate],MR.[LastSettlementDate]'

       
        if (@ItemLevel>0)
            set @sqlQuery = @sqlQuery +  ', MR.StoreNo, MR.SupplierAcctNo '
       
        if (@ItemLevel=2)
            set @sqlQuery = @sqlQuery +  ', MR.UPC'
           
        set @sqlQuery = @sqlQuery +  ' order by MR.Banner asc, '
       
        if (@ItemLevel>0)
            set @sqlQuery = @sqlQuery +  ' MR.StoreNo, '
           
         set @sqlQuery = @sqlQuery +  '  MR.LastInventoryCountDate desc, MR.LastSettlementDate desc'
        
        exec(@sqlQuery);
        
End
GO
