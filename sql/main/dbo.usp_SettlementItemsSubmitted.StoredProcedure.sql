USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_SettlementItemsSubmitted]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_SettlementItemsSubmitted]
    @ChainId varchar(10),
    @SupplierId varchar(10),
    @BannerId varchar(200),
    @StoreNo varchar(20),
    @SaleDate varchar(50),
    @ByUPC varchar(1),
    @UPC varchar(20),
    @Status varchar(6),
    @ShowAggregate varchar(1),
    @ProductIdentifierType int
as

Begin
 Declare @sqlQuery varchar(4000)
 begin try
	DROP TABLE [@tmpShrinkSettlementSubmitted]
	DROP TABLE [@tmpShrinkSettlementSubmittedResults]
end try
begin catch
end catch
     set @sqlQuery = 'SELECT  I.SupplierId, I.RetailerId, S.StoreID, S.StoreIdentifier as StoreNumber, S.Custom1 as Banner,
                     I.PhysicalInventoryDate as SaleDate,
                     sum(I.FinalInvoiceTotalCost) as FinalInvoiceTotalCost, sum(I.TotalQty) as TotalQty,
					sum(I.InvoiceAmount ) AS InvoiceAmount, Settle, I.RequestDate, I.ApprovedDate,DenialReason,
					(select firstname + '' '' + lastname from Persons where PersonId= I.RequestingPersonID)  as [RequestedBy],
					(select firstname + '' '' + lastname from Persons where PersonId= I.ApprovingPersonID)  as [ApprovedBy]'
	  
	 if (@ByUPC='Y') 
			 set @sqlQuery = @sqlQuery +  ',I.UPC, I.ProductId '  
                
     set @sqlQuery = @sqlQuery +  ' into [@tmpShrinkSettlementSubmitted] FROM  dbo.InventorySettlementRequests AS I
                     INNER JOIN dbo.Stores AS S ON I.StoreID = S.StoreID
                     WHERE I.SupplierID = ' + @SupplierId + '
                     and I.RetailerId=' + @ChainId
                   
     if (@ByUPC='Y') 
        set @sqlQuery = @sqlQuery +  ' AND I.UPC is not null'
                       
     if(@BannerId<>'-1')
        set @sqlQuery = @sqlQuery +  ' and S.custom1=''' + @BannerId + ''''
       
     if(@StoreNo <>'')
        set @sqlQuery = @sqlQuery +  ' and S.StoreIdentifier like ''%' + @StoreNo + '%'''
                   
     if(@UPC <>'')
        set @sqlQuery = @sqlQuery +  ' and I.UPC like ''%' + @UPC + '%''';
       
    if(@Status = 1)
        set @sqlQuery = @sqlQuery +  ' and I.ApprovedDate is Null'

    if(@Status = 2)
        set @sqlQuery = @sqlQuery +  ' and I.ApprovedDate is not Null'
       
    set @sqlQuery = @sqlQuery + ' group by I.SupplierId, I.RetailerId, S.StoreID, S.StoreIdentifier, S.custom1, I.PhysicalInventoryDate, Settle, I.RequestDate, I.ApprovedDate, RequestingPersonID, ApprovingPersonID, DenialReason'
   
    if (@ByUPC='Y') 
        set @sqlQuery = @sqlQuery + ' , I.UPC, I.ProductId '
   
    set @sqlQuery = @sqlQuery + ' order by Settle Asc, S.StoreID, S.StoreIdentifier, S.custom1, I.RequestDate,I.PhysicalInventoryDate desc'
   
    if (@ByUPC='Y') 
        set @sqlQuery = @sqlQuery + ',I.UPC, I.ProductId '

	execute ( @sqlQuery )
	
set @sqlQuery = 'SELECT  I.StoreID, I.StoreNumber, I.Banner,
				I.SaleDate, I.FinalInvoiceTotalCost,'
				
		if (@ByUPC='Y') 
			set @sqlQuery = @sqlQuery + ' I.UPC, I.ProductId, '				
        
		set @sqlQuery = @sqlQuery + '
				
						(SELECT SUM(TotalQty)
						 FROM [@tmpShrinkSettlementSubmitted] ID
						 where ID.StoreID = I.StoreID
						 and ID.Settle=I.Settle
						 and ID.RequestDate=I.RequestDate
						 and ID.SaleDate = I.SaleDate
						 and ID.SupplierID = I.SupplierId
						 and ID.RetailerId=I.RetailerId'
	
		if (@ByUPC='Y') 
			set @sqlQuery = @sqlQuery + ' and ID.ProductId=I.ProductId'
		
		set @sqlQuery = @sqlQuery + ') AS UnitCount, 
				 
				 (SELECT SUM(TotalQty)
						 FROM [@tmpShrinkSettlementSubmitted] ID
						 where ID.StoreID = I.StoreID
						 and ID.Settle=I.Settle
						 and ID.RequestDate=I.RequestDate
						 and ID.SaleDate <= I.SaleDate
						 and ID.SupplierID = I.SupplierId
						 and ID.RetailerId=I.RetailerId'
		if (@ByUPC='Y') 
			set @sqlQuery = @sqlQuery + ' and ID.ProductId=I.ProductId'
		
		set @sqlQuery = @sqlQuery + ') AS AggregateUnit, 
				 
				 (SELECT SUM(InvoiceAmount)
						 FROM [@tmpShrinkSettlementSubmitted] ID
						 where ID.StoreID = I.StoreID
						 and ID.Settle=I.Settle
						 and ID.RequestDate=I.RequestDate
						 and ID.SaleDate <= I.SaleDate
						 and ID.SupplierID = I.SupplierId
						 and ID.RetailerId=I.RetailerId'
						 
		if (@ByUPC='Y') 
			set @sqlQuery = @sqlQuery + ' and ID.ProductId=I.ProductId'
		
		set @sqlQuery = @sqlQuery + ') AS Aggregate, 
	                    
				I.InvoiceAmount, I.Settle, I.RequestDate, I.ApprovedDate,I.DenialReason,
				I.[RequestedBy],I.[ApprovedBy] '
	 
	 set @sqlQuery = @sqlQuery +  ' into [@tmpShrinkSettlementSubmittedResults]  FROM  [@tmpShrinkSettlementSubmitted] AS I'
	 
	 if(@ShowAggregate='Y')      
		begin
			set @sqlQuery = @sqlQuery + '	Where (I.SaleDate)=(select max(saledate) from [@tmpShrinkSettlementSubmitted] ID
					where ID.StoreID = I.StoreID
						 and ID.Settle=I.Settle
						 and ID.RequestDate=I.RequestDate
						 and ID.SupplierID = I.SupplierId
						 and ID.RetailerId=I.RetailerId)'
		end		
		
	 set @sqlQuery = @sqlQuery + ' order by Settle Asc, Banner, StoreNumber, SaleDate desc'
   
    if (@ByUPC='Y') 
        set @sqlQuery = @sqlQuery + ',I.UPC '

	exec (@sqlQuery)

	
	set @sqlQuery = 'select StoreID, StoreNumber, Banner,
				SaleDate, FinalInvoiceTotalCost, UnitCount, AggregateUnit, Aggregate, InvoiceAmount, 
				case when unitcount is null then ''Initialization'' else Settle end as Settle,
				RequestDate, ApprovedDate, DenialReason,
				RequestedBy, ApprovedBy '
	  
	if (@ByUPC='Y') 
		 set @sqlQuery = @sqlQuery +  ', UPC, ProductId ' 
		 
	set @sqlQuery = @sqlQuery +  ' from [@tmpShrinkSettlementSubmittedResults]'
	set @sqlQuery = @sqlQuery + ' order by Settle Asc, Banner, StoreNumber, SaleDate desc'
		
	exec (@sqlQuery)

	begin try
		DROP TABLE [@tmpShrinkSettlementSubmitted]
		DROP TABLE [@tmpShrinkSettlementSubmittedResults]
	end try
	begin catch
	end catch

End
GO
