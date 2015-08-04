USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_DisputPendingStatus]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec [usp_DisputPendingStatus] '-1','','','All'

CREATE procedure [dbo].[usp_DisputPendingStatus]
 @SupplierId varchar(5),
 @StoreId varchar(5),
 @ProductIdentifier varchar(50),
 @WhoseRecordsAreCorrect varchar(50)
 
as
 
Begin
 Declare @sqlQuery varchar(4000)
 
 set @sqlQuery = ' Select distinct
						D.ReconcileId 
						, S.StoreIdentifier as [Store Number]
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
						, ID.RetailerInvoiceID AS [Invoice No]
						, D.PaymentId

				From DisputeResolution D with (nolock)  
				Inner join Stores S with (nolock)   on S.StoreId=D.StoreId
				Inner join ProductIdentifiers P with (nolock) on P.ProductId=D.ProductId and P.ProductIdentifierTypeId=2
				Inner Join Chains C with (nolock) on  C.ChainID=S.ChainID
				INNER JOIN InvoiceDetails ID with (nolock) ON D.ProductId=ID.ProductID AND D.StoreId=ID.StoreID AND ID.ChainID=C.ChainID AND D.PaymentID=ID.PaymentID 
				where 1=1 and D.PaymentProcessed=0 and D.SupplierDecision is null ' 
                
 if(@SupplierId<>'-1')
	set @sqlQuery = @sqlQuery +  ' and ID.SupplierID=' + @SupplierId
		
 if(@StoreId<>'')
	set @sqlQuery = @sqlQuery + ' and S.StoreIdentifier=' + @StoreId
 
 if(@ProductIdentifier<>'')
	set @sqlQuery = @sqlQuery + ' and P.IdentifierValue like ''%' + @ProductIdentifier + '%''' 
	
 if(@WhoseRecordsAreCorrect<>'All')
	set @sqlQuery = @sqlQuery + ' and D.CorrectRecord='''+ @WhoseRecordsAreCorrect +''''
	
print @sqlQuery 
execute(@sqlQuery);
 
End
GO
