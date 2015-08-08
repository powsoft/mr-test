USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_PaymentDetails_PRESYNC_20150524]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_PaymentDetails_PRESYNC_20150524]
@PaymentId varchar(20),
@Banner varchar(20),
@StoreId varchar(20),
@ShowDifferences varchar(1),
@ProductIdentifierType int,
@ProductIdentifierValue varchar(50),
@Status varchar(20),
@SupplierID varchar(20),
@WhereWeAre varchar(10),
@PONo varchar(100)

-- exec [usp_PaymentDetails] '61621','Meijer, Inc.','-1',1,2,'','-1','81666','0',''
As
Begin

Declare @sqlQuery varchar(max)

	set @sqlQuery = 'select D.PaymentId,D.StoreId, D.ProductId,ss.SupplierName, 
	                 D.RetailerInvoiceId  AS [Invoice No],
	                 D.InvoiceNo  AS [Supplier Invoice No],
	                 convert(varchar(12),D.SaleDate,101) AS [Sale Date],
					 substring(ST.Custom1,1,3)+'' ''+ Convert(varchar(20),ST.StoreIdentifier) as [Store Number], PD.IdentifierValue, 	
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
			
 set @sqlQuery += ' from InvoiceDetails D With(NoLock) 
					inner join suppliers ss on ss.SupplierID=D.SupplierID
					inner join Stores ST With(NoLock) on ST.StoreId=D.StoreId
					inner join ProductIdentifiers PD With(NoLock) on PD.ProductId=D.ProductId and PD.ProductIdentifierTypeId=2
					full outer join (select ChainId, SupplierId, StoreId, ProductId, SaleDateTime, sum(Qty) as ReceivedQty , RuleCost , SupplierInvoiceNumber,PONo
									from StoreTransactions S With(NoLock) 
									where S.TransactionTypeId=32
									group by ChainId, SupplierId, StoreId, ProductId, SaleDateTime, RuleCost,SupplierInvoiceNumber,PONo
									) S on D.SupplierId=S.SupplierId and D.ChainId=S.ChainId and D.StoreId=S.StoreId and D.ProductId=S.ProductId and D.SaleDate=S.SaleDateTime and S.SupplierInvoiceNumber=D.InvoiceNo

					left join DisputeResolution DS With(NoLock) on DS.ProductId=PD.ProductId AND DS.StoreId=ST.StoreID AND Ds.PaymentId=D.PaymentID	
					Left Join (select distinct ChainId, SupplierId, SupplierInvoiceNumber, PONo
									from StoreTransactions ST With(NoLock) 
									where ST.TransactionTypeId=32
									group by ChainId, SupplierId, SupplierInvoiceNumber, PONo
							  ) PO on PO.SupplierId=D.SupplierId and D.ChainId=PO.ChainId and D.InvoiceNo=PO.SupplierInvoiceNumber	
					where 1=1 '
                 
    if(@PaymentId<>'-1' and @PaymentId<>'' and @SupplierID<>'-1')
        set @sqlQuery = @sqlQuery + ' and D.PaymentId=' + @PaymentId 
  
    if(@SupplierID<>'-1' and @SupplierID <>'')
        set @sqlQuery = @sqlQuery + ' and D.SupplierID=' + @SupplierID
        
   	if(@Banner<>'-1' and @Banner<>'')
        set @sqlQuery = @sqlQuery + ' and St.Custom1 = ''' + @Banner+''''

	if(@StoreId<>'-1' and @StoreId<>'')
        set @sqlQuery = @sqlQuery + ' and ST.StoreId = ' + @StoreId 
        
    --if(@ProductId<>'-1' and @ProductId<>'')
    --    set @sqlQuery = @sqlQuery + ' and D.ProductId = ' + @ProductId  
        
  if(@ProductIdentifierValue<>'')	
			set @sqlQuery = @sqlQuery + ' and PD.IdentifierValue like ''%' + @ProductIdentifierValue + '%'''	
	
	 
	 if (@ProductIdentifierType=2)
			set @sqlQuery = @sqlQuery + ' and Pd.ProductIdentifierTypeID=2'

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
			
	set @sqlQuery = @sqlQuery + ' group by D.SupplierId, D.ChainId, D.PaymentId,D.StoreId, D.ProductId,ss.SupplierName, D.SaleDate, D.RetailerInvoiceId,D.InvoiceNo,
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
