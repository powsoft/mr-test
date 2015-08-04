USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_PaymentsMismatch_All]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--  usp_Report_PaymentsMismatch 62362, 0,'-1','-1','28187','-1',5,'01/23/2013','01/24/2013'
CREATE procedure [dbo].[usp_Report_PaymentsMismatch_All]

@chainID varchar(max),
@PersonID int,
@Banner varchar(50),
@ProductUPC varchar(20),
@SupplierId varchar(max),
@StoreId varchar(10),
@LastxDays int,
@StartDate varchar(20),
@EndDate varchar(20)
  
as
Begin
Declare @sqlQuery varchar(max)
Declare @AttValue int
Declare @CostFormat varchar(10)

	if(@supplierID<>'-1')
		Select @CostFormat = Costformat from SupplierFormat WITH(NOLOCK)  where SupplierID = @supplierID
	 else
		set @CostFormat=4	
		set @CostFormat = ISNULL(@CostFormat , 4)
 	
 select @attvalue = AttributeID  from AttributeValues WITH(NOLOCK)  where OwnerEntityID=@PersonID and AttributeID=17
 
 set @sqlQuery =  'Select distinct P.PaymentId, C.ChainName as [Retailer Name],S.SupplierName as [Supplier Name], 
				P.AmountOriginallyBilled, I.[To Pay Amount],(P.AmountOriginallyBilled - I.[To Pay Amount]) as [Difference], 
				ST.StatusName as [Payment Status]
				from Payments P  with (nolock)
				inner join Statuses ST on ST.StatusIntValue = P.PaymentStatus and ST.StatusTypeID=14
				inner join Suppliers S on S.SupplierID=P.PayeeEntityID
				inner join Chains C on C.ChainID=P.PayerEntityID
				inner join (Select I.PaymentID, sum(isnull(TotalQty*UnitCost,0))  as [To Pay Amount]
						  from InvoiceDetails I  with (nolock)
						  inner join InvoicesSupplier SI with (nolock) on SI.SupplierInvoiceId = I.SupplierInvoiceId
						  group by I.PaymentID
						  ) I on P.PaymentId=I.PaymentID
				where abs(P.AmountOriginallyBilled-[To Pay Amount])>1 
				and P.PaymentStatus>2 and P.DateTimeCreated > getdate()-120'

	if(@ChainId <>'-1') 
		set @sqlQuery = @sqlQuery + ' and C.ChainID in (' + @ChainId + ')'
  
	if(@SupplierID <>'-1') 
		set @sqlQuery = @sqlQuery + ' and S.SupplierId in (' + @SupplierId+ ')'

	set @sqlQuery = @sqlQuery + ' Order by P.PaymentId desc '
	
	print(@sqlQuery);
	execute(@sqlQuery); 
			
End
GO
