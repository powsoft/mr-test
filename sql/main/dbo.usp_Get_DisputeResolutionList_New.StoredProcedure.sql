USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Get_DisputeResolutionList_New]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec [usp_Get_DisputeResolutionList] '-1','-1','','-1','All','-1'

CREATE procedure [dbo].[usp_Get_DisputeResolutionList_New]
 @ChainId varchar(5),
 @StoreId varchar(5),
 @ProductIdentifier varchar(50),
 @Status varchar(50),
 @WhoseRecordsAreCorrect varchar(50),
 @SupplierID Varchar(20)
as
 
Begin
 Declare @sqlQuery varchar(4000)
 
 set @sqlQuery = 'Select distinct D.ReconcileId 
								, IC.StoreID as [Store Number]
								, P.IdentifierValue as UPC
								, D.Old_Qnt as  [Distributor Qty]
								, cast(D.Old_Cost as numeric(10,2)) as [Distributor Cost]
								, D.Old_Qnt*cast(D.Old_Cost as numeric(10,2)) as [Distributor Amount]
								, D.New_Qnt as [Receiving Qty] 
								, cast(D.New_Cost as numeric(10,2)) as [Receiving Cost]
								, D.New_Qnt*cast(D.New_Cost as numeric(10,2)) as [Receiving Amount]
								, cast(D.PostOffValue as numeric(10,2)) as PostOff
								, D.CorrectRecord as [WhoseRecordsAreCorrect]
								, cast(D.DifferenceAmount as numeric(10,2)) as Differential
								, IC.InvoiceNumber as [Receiving Invoice#]
								, IC.SupplierInvoiceNumber as [Delivery Invoice#]
								, D.PaymentId
								, Convert(varchar(12),ID.SaleDate,103) AS [Sale Date]
								, D.Comments
								, D.CreditReferenceNo
								, CASE WHEN D.PaymentProcessed = 0 and D.SupplierDecision is null THEN ''Pending''
								  WHEN D.PaymentProcessed=0 and D.SupplierDecision=1  THEN ''Rejected''
								  WHEN D.PaymentProcessed=0 and D.SupplierDecision=2 THEN ''Approved'' ELSE ''Processed'' END AS Status 
								, D.PONo as PONumber
					From DisputeResolution_New D with (nolock)
					INNER JOIN DataTrue_main..iCAM_POMatch IC with (nolock) ON isnull(IC.SupplierInvoiceNumber, IC.InvoiceNumber)=D.InvoiceNumber
								and IC.PaymentID=D.PaymentId and IC.StoreID=D.StoreId
					INNER JOIN InvoiceDetails ID with (nolock) ON ID.InvoiceNo  = isnull(IC.SupplierInvoiceNumber, IC.InvoiceNumber) 
								and id.PaymentID=IC.PaymentID and id.StoreID=IC.StoreID
					Inner join ProductIdentifiers P with (nolock) on P.ProductId=D.ProductId and P.ProductIdentifierTypeId=2 ' 
                
 if(@ChainId<>'-1')
	set @sqlQuery = @sqlQuery +  ' and IC.ChainID=' + @ChainID

 if(@SupplierID<>'-1')
	set @sqlQuery = @sqlQuery +  ' and IC.SupplierID=' + @SupplierID
		
 if(@StoreId<>'-1')
	set @sqlQuery = @sqlQuery + ' and IC.StoreId=' + @StoreId
 
 if(@ProductIdentifier<>'')
	set @sqlQuery = @sqlQuery + ' and P.IdentifierValue like ''%' + @ProductIdentifier + '%''' 
	
 if(@WhoseRecordsAreCorrect<>'All')
	set @sqlQuery = @sqlQuery + ' and D.CorrectRecord='''+ @WhoseRecordsAreCorrect +''''
 
 if(@Status<>'-1' or @Status<>'All')
	 begin
		if(upper(@Status)=upper('Pending'))
			set @sqlQuery = @sqlQuery + ' and D.PaymentProcessed=0 and D.SupplierDecision is null '
			
		if(upper(@Status)=upper('Rejected'))
			set @sqlQuery = @sqlQuery + ' and D.PaymentProcessed=0 and D.SupplierDecision=1 '
			
		if(upper(@Status)=upper('Approved'))
			set @sqlQuery = @sqlQuery + ' and D.PaymentProcessed=0 and D.SupplierDecision=2 '
			
		if(upper(@Status)=upper('Processed'))
			set @sqlQuery = @sqlQuery + ' and D.PaymentProcessed=1 '
	 end

print @sqlQuery 
execute(@sqlQuery);
 
End
GO
