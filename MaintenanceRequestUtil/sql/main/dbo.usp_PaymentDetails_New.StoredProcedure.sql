USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_PaymentDetails_New]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_PaymentDetails_New]
@InvoiceNo varchar(50),
@Banner varchar(20),
@StoreId varchar(20),
@ShowDifferences varchar(1),
@ProductIdentifierType int,
@ProductIdentifierValue varchar(50),
@Status varchar(20),
@SupplierID varchar(20),
@WhereWeAre varchar(10),
@PONo varchar(100)

-- exec [usp_PaymentDetails_New] '265458','Meijer, Inc.','-1',1,2,'','-1','81650','0',''
As
Begin

Declare @sqlQuery varchar(max)

	set @sqlQuery = 'select IC.PaymentId,D.StoreId, D.ProductId,ss.SupplierName,
					 IC.InvoiceNumber as [Receiving Invoice#],
					 IC.SupplierInvoiceNumber as [Delivery Invoice#], 
	                 convert(varchar(12),IC.InvoiceDate,101) AS [Invoice Date],
					 substring(ST.Custom1,1,3)+'' ''+ Convert(varchar(20),
					 ST.StoreIdentifier) as [Store Number], 
					 PD.IdentifierValue, 	
					 cast(sum(D.TotalQty) as numeric(10,0)) as [Distributor Qty], 
					 cast(D.UnitCost as numeric(10,2)) as [Distributor Cost],
					(cast(sum(D.TotalQty) as numeric(10,0)) * cast(D.UnitCost as numeric(10,2))) as [TotalDistributorCost],
					cast(sum(isnull(D.Adjustment1,0)+ isnull(D.Adjustment2,0)+ isnull(D.Adjustment3,0)+ isnull(D.Adjustment4,0)+ isnull(D.Adjustment5,0)+ isnull(D.Adjustment6,0)+ isnull(D.Adjustment7,0)+ isnull(D.Adjustment8,0)) as numeric(10,2)) AS [Distributor Adjustment],
	                cast(((cast(sum(D.TotalQty) AS NUMERIC(10, 0)) * cast(D.UnitCost AS NUMERIC(10, 2)))+ sum(isnull(D.Adjustment1,0)+ isnull(D.Adjustment2,0)+ isnull(D.Adjustment3,0)+ isnull(D.Adjustment4,0)+ isnull(D.Adjustment5,0)+ isnull(D.Adjustment6,0)+ isnull(D.Adjustment7,0)+ isnull(D.Adjustment8,0))) as numeric(10,2)) AS [Distributor Net Cost],
					cast(S.ReceivedQty as numeric(10,0)) as [Receiving Qty], 
					cast(S.[RuleCost] as numeric(10,2)) as [Receiving Cost],
					(cast(S.ReceivedQty as numeric(10,0)) *  cast(S.[RuleCost] as numeric(10,2))) as [TotalReceivingCost],
					cast((sum(isnull(D.TotalQty,0)) * isnull(D.UnitCost,0)) - (isnull(S.ReceivedQty,0) * isnull(S.[RuleCost],0)) as numeric(10,2)) as Differential,
					cast(DS.PostOffValue as numeric(10,2)) as PostOffValue, 
					cast(DS.DifferenceAmount as numeric(10,2)) as DifferenceAmount, 
					DS.CorrectRecord,DS.Comments,
					Case When DS.PaymentProcessed=0 and DS.SupplierDecision=2 Then ''Approved''
					When DS.PaymentProcessed=0 and DS.SupplierDecision is null Then ''Pending Supplier''
					When DS.PaymentProcessed=0 and DS.SupplierDecision=1 Then ''Rejected'' 
					When DS.PaymentProcessed=1 Then ''Processed'' 
					When DS.PaymentProcessed IS NULL Then ''Pending Retailer'' 
					End as PaymentStatus,
					Ds.CreditReferenceNo AS ReferenceNo	,
					PO.PONo as PONumber '		
			
	set @sqlQuery += ' from DataTrue_main..iCAM_POMatch IC With(NoLock)
					inner join InvoiceDetails D With(NoLock) on D.InvoiceNo = isnull(IC.SupplierInvoiceNumber, IC.InvoiceNumber) AND IC.PaymentID=D.PaymentID
					inner join suppliers ss on ss.SupplierID=IC.SupplierID
					inner join Stores ST With(NoLock) on ST.StoreId=IC.StoreId
					inner join ProductIdentifiers PD With(NoLock) on PD.ProductId=D.ProductId and PD.ProductIdentifierTypeId = 2
					full outer join (select ChainId, SupplierId, StoreId, ProductId, SaleDateTime, sum(Qty) as ReceivedQty , RuleCost , SupplierInvoiceNumber,PONo
										from StoreTransactions S With(NoLock) 
										where S.TransactionTypeId=32
										group by ChainId, SupplierId, StoreId, ProductId, SaleDateTime, RuleCost,SupplierInvoiceNumber,PONo
									 ) S on IC.SupplierId=S.SupplierId and IC.ChainId=S.ChainId 
										and IC.StoreId=S.StoreId and D.ProductId=S.ProductId 
										and IC.InvoiceDate=S.SaleDateTime and S.SupplierInvoiceNumber=isnull(IC.SupplierInvoiceNumber, IC.InvoiceNumber)

					left join DisputeResolution_New DS With(NoLock) on DS.ProductId=D.ProductId AND DS.StoreId=D.StoreID AND Ds.InvoiceNumber = isnull(IC.SupplierInvoiceNumber, IC.InvoiceNumber)
					Left Join (select distinct ChainId, SupplierId, SupplierInvoiceNumber, PONo
									from StoreTransactions ST With(NoLock) 
									where ST.TransactionTypeId=32
									group by ChainId, SupplierId, SupplierInvoiceNumber, PONo
							   ) PO on PO.SupplierId=IC.SupplierId and IC.ChainId=PO.ChainId and isnull(IC.SupplierInvoiceNumber, IC.InvoiceNumber)=PO.SupplierInvoiceNumber	
					where 1=1 '
    
    if(@InvoiceNo<>'')
         set @sqlQuery = @sqlQuery + ' and isnull(IC.SupplierInvoiceNumber, IC.InvoiceNumber) = ''' + @InvoiceNo + ''''
                
    if(@SupplierID<>'-1' and @SupplierID <>'')
        set @sqlQuery = @sqlQuery + ' and IC.SupplierID=' + @SupplierID
        
   	if(@Banner<>'-1' and @Banner<>'')
        set @sqlQuery = @sqlQuery + ' and St.Custom1 = ''' + @Banner+''''

	if(@StoreId<>'-1' and @StoreId<>'')
        set @sqlQuery = @sqlQuery + ' and ST.StoreId = ' + @StoreId 
        
	if(@ProductIdentifierValue<>'')	
			set @sqlQuery = @sqlQuery + ' and PD.IdentifierValue like ''%' + @ProductIdentifierValue + '%'''	
	
	 
	 if (@ProductIdentifierType=2)
			set @sqlQuery = @sqlQuery + ' and Pd.ProductIdentifierTypeID = 2'

	else if (@ProductIdentifierType=1)
			set @sqlQuery = @sqlQuery + ' and Pd.ProductIdentifierTypeID=1'	 
	
	 if(@Status<>'-1' or @Status<>'All')
	 begin
		if(upper(@Status)=upper('Pending'))
			set @sqlQuery = @sqlQuery + ' and DS.PaymentProcessed=0 and DS.SupplierDecision is null '
			
		if(upper(@Status)=upper('Rejected'))
			set @sqlQuery = @sqlQuery + ' and DS.PaymentProcessed=0 and DS.SupplierDecision=1 '
			
		if(upper(@Status)=upper('Approved'))
			set @sqlQuery = @sqlQuery + ' and DS.PaymentProcessed=0 and DS.SupplierDecision=2 '
			
		if(upper(@Status)=upper('Processed'))
			set @sqlQuery = @sqlQuery + ' and DS.PaymentProcessed=1 '
			
		if(upper(@Status)=upper('PendingRetailer'))
			set @sqlQuery = @sqlQuery + ' and DS.PaymentProcessed is null '
	 end
	
	if(@PONo<>'')	
			set @sqlQuery = @sqlQuery + ' and PO.PONo like ''%' + @PONo + '%'''
			
	set @sqlQuery = @sqlQuery + ' group by D.SupplierId, D.ChainId, IC.PaymentId,D.StoreId, D.ProductId,ss.SupplierName, IC.InvoiceDate, 
										   IC.InvoiceNumber,IC.SupplierInvoiceNumber,
										   ST.Custom1, ST.StoreIdentifier,PD.IdentifierValue ,
										   D.UnitCost, S.RuleCost,DS.PostOffValue,DS.DifferenceAmount,DS.CorrectRecord,DS.Comments,S.ReceivedQty,
										   DS.PaymentProcessed, DS.SupplierDecision, Ds.CreditReferenceNo,PO.PONo  HAVING 1=1 '

	if(@ShowDifferences='1')
			set @sqlQuery = @sqlQuery + ' AND ISNULL(cast((sum(isnull(D.TotalQty,0)) * isnull(D.UnitCost,0)) + sum(isnull(D.Adjustment1,0)+ isnull(D.Adjustment2,0)+ isnull(D.Adjustment3,0)+ isnull(D.Adjustment4,0)+ isnull(D.Adjustment5,0)+ isnull(D.Adjustment6,0)+ isnull(D.Adjustment7,0)+ isnull(D.Adjustment8,0)) - (isnull(S.ReceivedQty,0) * isnull(S.[RuleCost],0)) as numeric(10,2)),0) <> 0 '

    IF(@WhereWeAre = '2')
			set @sqlQuery = @sqlQuery + ' AND isnull(sum(isnull(D.TotalQty,0)) * isnull(D.UnitCost,0),0)  = 0 '
			
    ELSE IF(@WhereWeAre = '1')
			set @sqlQuery = @sqlQuery + ' AND isnull(isnull(S.ReceivedQty,0) * isnull(S.[RuleCost],0),0)  = 0 '
			
    					
	set @sqlQuery = @sqlQuery + ' order by 1, 2 '
	   
	print @sqlQuery     
    exec (@sqlQuery)
   
    
End
GO
