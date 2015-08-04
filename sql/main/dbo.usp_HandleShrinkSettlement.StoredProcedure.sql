USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_HandleShrinkSettlement]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--[dbo].[usp_HandleShrinkSettlement] '50721','62348', 'Walmart', '10/6/2013','9/23/2013','1440', 'Settle', '', '64040',NULL
CREATE Procedure [dbo].[usp_HandleShrinkSettlement]
     @SupplierId varchar(20),
     @ChainId varchar(20),
     @Banner varchar(50),
     @PhysicalInventoryDate datetime ,
     @BIDate datetime ,
     @StoreNumber nvarchar(50) ,
     @NewStatus varchar(50),
     @UPC varchar(50),
     @RequestingPersonId varchar(20),
     @Reason varchar(500),
     @GLCode varchar(50)
as
begin
    Declare @strSQL varchar(4000)
 
 
    if(@NewStatus='Settle')
        Begin
        
  --     Select SupplierId, chainid, StoreId, ProductId, max(IR1.LastInventoryCountDate) as MaxDate 
		--into #tmpMaxDate
		--from InventoryReport_New_FactTable_Active IR1
		--where IR1.LastInventoryCountDate<= convert(varchar(10), @PhysicalInventoryDate, 101) 
		--Group by  SupplierId, chainid, StoreId, ProductId 
																										
            set @strSQL= 'Insert into InventorySettlementRequests
                        ([supplierId] ,[retailerId], [GLCode], [UPC], [ProductID],[Banner], [StoreNumber], [StoreID] ,[PhysicalInventoryDate], [PriorInventoryCountDate],
						 [Settle], [RequestingPersonID], [RequestDate],
						 [BI Count], [BI$] ,[Net Deliveries] ,[Net Deliveries$], [Net POS],[InvoiceAmount],[UnsettledShrink],
						 [POS$] ,[Expected EI] ,[Expected EI$] ,[LastCountQty] ,[LastCount$],
						 [ShrinkUnits] ,[Shrink$] ,[SupplierUniqueProductID] ,[NetUnitCostLastCountDate] ,[BaseCostLastCountDate],
						 [WeightedAvgCost],[SharedShrinkUnits],[SupplierAcctNo],[RouteNo])
                     
                        Select I.SupplierID, I.ChainID, I.GLCode, I.UPC, I.ProductID,I.Banner, I.StoreNo, I.StoreID, I.LastInventoryCountDate, I.LastSettlementDate,
                        ''Pending'', ' + @RequestingPersonId + ',''' + convert(varchar(10), getdate(), 101) + ''', I.[BI Count], I.BI$, I.[Net Deliveries], I.[Net Deliveries$],
                        I.[Net POS],0, 0, I.POS$, I.[Expected EI] ,I.[Expected EI$],I.[LastCountQty] ,I.[LastCount$],
                        I.ShrinkUnits, I.Shrink$,I.[SupplierUniqueProductID], I.[NetUnitCostLastCountDate], I.[BaseCostLastCountDate],
                        I.[WeightedAvgCost],I.[SharedShrinkUnits], I.[SupplierAcctNo],i.[RouteNo]
                        from InventoryReport_New_FactTable_Active I with(NOLOCK) 
                        left join InventorySettlementRequests IR with(NOLOCK) on IR.SupplierId=I.SupplierId and IR.RetailerId=I.ChainId
							and IR.ProductID=I.ProductID and IR.StoreID=I.StoreID and ir.Settle =''Pending'' and I.LastInventoryCountDate=IR.PhysicalInventoryDate
                        where I.SupplierID=' + @SupplierId + ' and I.Banner=''' + @Banner + ''' 
                        and I.LastInventoryCountDate <= '''  + convert(varchar(10), @PhysicalInventoryDate, 101)  + '''
                        and IR.SupplierId is null'
                        
                        if(@ChainId<>'-1')
                            set @strSQL = @strSQL + ' and I.ChainId=''' + @ChainId + ''''
                                
                        if (@StoreNumber<>'')
							set @strSQL = @strSQL + ' and I.StoreNo='''  + @StoreNumber + ''''
             
                        if(@UPC<>'')
                                set @strSQL = @strSQL + ' and I.UPC=''' + @UPC + ''''
                                
                        if(@GLCode<>'')
                                set @strSQL = @strSQL + ' and I.GLCode = ''' + @GLCode + ''''        
                     print @strSQL 
                                                     
        End
    else if(@NewStatus='Unsettle')
        Begin
            set @strSQL= 'Delete from InventorySettlementRequests
            where supplierId=' + @SupplierId + ' 
            and PhysicalInventoryDate<=''' + convert(varchar(10),@PhysicalInventoryDate, 101) + ''' and Settle=''Pending'''
			
            if(@ChainId<>'-1')
                set @strSQL = @strSQL + ' and RetailerId=' + @ChainId
            
            if (@StoreNumber<>'')
				set @strSQL = @strSQL + ' and StoreNumber='''  + @StoreNumber + ''''
			
			if (@Banner<>'')
				set @strSQL = @strSQL + ' and Banner = '''  + @Banner + ''''							 
				
            if(@UPC<>'')
                set @strSQL = @strSQL + ' and UPC=''' + @UPC + ''''
                
            if(@GLCode<>'')
                set @strSQL = @strSQL + ' and GLCode = ''' + @GLCode + ''''    
        End   
    else 
        Begin
            set @strSQL= 'Update InventorySettlementRequests
			set Settle=''' + @NewStatus + ''', ApprovingPersonId=' + @RequestingPersonId + ', 
			DenialReason=''' + @Reason + ''', ApprovedDate=''' + convert(varchar(10), GETDATE(),101) + ''' 
			where supplierId=' + @SupplierId + ' 
            and PhysicalInventoryDate<=''' + convert(varchar(10),@PhysicalInventoryDate, 101) + ''' and Settle=''Pending'''
         
            if(@ChainId<>'-1')
                set @strSQL = @strSQL + ' and RetailerId=' + @ChainId
             
            if (@StoreNumber<>'')
				set @strSQL = @strSQL + ' and StoreNumber='''  + @StoreNumber + ''''
			
			if (@Banner<>'')
				set @strSQL = @strSQL + ' and Banner = '''  + @Banner + ''''
			
            if(@UPC<>'')
                set @strSQL = @strSQL + ' and UPC=''' + @UPC + ''''
                
            if(@GLCode<>'')
                set @strSQL = @strSQL + ' and GLCode = ''' + @GLCode + ''''     
        End   


--    print(@strSQL)
    exec (@strSQL)
        
end
GO
