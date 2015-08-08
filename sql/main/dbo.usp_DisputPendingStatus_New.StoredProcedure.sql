USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_DisputPendingStatus_New]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec [usp_DisputPendingStatus_New] '81650','','','All'

CREATE procedure [dbo].[usp_DisputPendingStatus_New]
 @SupplierId varchar(5),
 @StoreId varchar(5),
 @ProductIdentifier varchar(50),
 @WhoseRecordsAreCorrect varchar(50)
 
as
 
Begin
 Declare @sqlQuery varchar(4000)
 
 set @sqlQuery = ' Select distinct
						D.ReconcileId 
						, IC.StoreID as [Store Number]
						, P.IdentifierValue as UPC
						, Convert(varchar(12),ID.SaleDate,103) AS [Sale Date]
						, D.PONo as PONumber
						, D.Old_Qnt as  [Distributor Qty]
						, cast(D.Old_Cost as numeric(10,2)) as [Distributor Cost]
						, D.Old_Qnt*cast(D.Old_Cost as numeric(10,2)) as [Distributor Amount]
						, D.New_Qnt as [Receiving Qty] 
						, cast(D.New_Cost as numeric(10,2)) as [Receiving Cost]
						, D.New_Qnt*cast(D.New_Cost as numeric(10,2)) as [Receiving Amount]
						, cast(D.PostOffValue as numeric(10,2)) as PostOff
						, D.CorrectRecord as [WhoseRecordsAreCorrect]
						, cast(D.DifferenceAmount as numeric(10,2)) as Differential
						, isnull(IC.SupplierInvoiceNumber, IC.InvoiceNumber) AS [Invoice No]
						, D.PaymentId

				From DisputeResolution_New D with (nolock)  
				INNER JOIN DataTrue_main..iCAM_POMatch IC with (nolock) ON isnull(IC.SupplierInvoiceNumber, IC.InvoiceNumber)=D.InvoiceNumber
								and IC.PaymentID=D.PaymentId and IC.StoreID=D.StoreId
				INNER JOIN InvoiceDetails ID with (nolock) ON ID.InvoiceNo  = isnull(IC.SupplierInvoiceNumber, IC.InvoiceNumber) 
								and id.PaymentID=IC.PaymentID and id.StoreID=IC.StoreID					
				Inner join ProductIdentifiers P with (nolock) on P.ProductId=D.ProductId and P.ProductIdentifierTypeId=2
				--Inner Join Chains C with (nolock) on  C.ChainID=S.ChainID
				--INNER JOIN InvoiceDetails ID with (nolock) ON D.ProductId=ID.ProductID AND D.StoreId=ID.StoreID AND ID.ChainID=C.ChainID AND ID.RetailerInvoiceID=D.InvoiceNumber 
				where 1=1 and D.PaymentProcessed=0 and D.SupplierDecision is null ' 
                
 if(@SupplierId<>'-1')
	set @sqlQuery = @sqlQuery +  ' and IC.SupplierID=' + @SupplierId
		
 if(@StoreId<>'')
	set @sqlQuery = @sqlQuery + ' and IC.StoreID=' + @StoreId
 
 if(@ProductIdentifier<>'')
	set @sqlQuery = @sqlQuery + ' and P.IdentifierValue like ''%' + @ProductIdentifier + '%''' 
	
 if(@WhoseRecordsAreCorrect<>'All')
	set @sqlQuery = @sqlQuery + ' and D.CorrectRecord='''+ @WhoseRecordsAreCorrect +''''
	
print @sqlQuery 
execute(@sqlQuery);
 
End
GO
