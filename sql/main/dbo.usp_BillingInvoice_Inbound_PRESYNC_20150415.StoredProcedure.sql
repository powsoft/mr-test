USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_BillingInvoice_Inbound_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- select * from DataTrue_EDI.dbo.InboundInventory_Web 
-- exec usp_BillingInvoice_Inbound 'Supervalu','','','41468'
CREATE Procedure [dbo].[usp_BillingInvoice_Inbound_PRESYNC_20150415]
@ChainName varchar(50),
@InvoiceNumber varchar(255),
@StoreNumber varchar(50),
@SupplierId varchar(50)

AS
Begin
Declare @sqlQuery varchar(4000)

    SET @sqlQuery = ' SELECT distinct ChainName AS [Chain Name],
									  s.SupplierName AS [Supplier Name],
									  ReportingLocation AS [Store Name],
									  StoreNumber AS [Store No],
									  ReferenceIdentification AS [Invoice No] ,
									  CONVERT(VARCHAR(10),EffectiveDate,101) as [Invoice Date],
									  case when RecordStatus = 1 then ''Pending''
										   when RecordStatus = 0 then ''Approved''
										   when RecordStatus = 6 then ''Approved''
										   when RecordStatus = 2 then ''Processed''
										   when RecordStatus = 5 then ''Parked''
										   end AS Status
						    
                        
					  FROM DataTrue_EDI.dbo.InboundInventory_Web as a with(nolock) 
					  inner join suppliers as s with(nolock)  on s.supplierid=a.DataTrueSupplierID
					     
                      Where 1=1 '
     
     IF(@ChainName<>'-1')
		SET @sqlQuery = @sqlQuery + ' and ChainName=''' + @ChainName + ''''
		
	IF(@InvoiceNumber<>'')
		SET @sqlQuery = @sqlQuery + ' and ReferenceIdentification=''' + @InvoiceNumber + ''''
		
    IF(@StoreNumber<>'')
		SET @sqlQuery = @sqlQuery + ' and StoreNumber=''' + @StoreNumber + '''' 		
      
    SET @sqlQuery = @sqlQuery + ' and a.DataTrueSupplierID=''' + @SupplierID +'''' + ' Order BY ChainName '
                                   
    exec(@sqlQuery)       
    PRINT(@sqlQuery)                              
                                   
End
GO
