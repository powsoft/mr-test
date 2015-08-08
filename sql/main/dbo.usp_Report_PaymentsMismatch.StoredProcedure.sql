USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_PaymentsMismatch]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--  usp_Report_PaymentsMismatch -1, 65665,'-1','-1','-1','-1',5,'01/23/2013','01/24/2013'
CREATE procedure [dbo].[usp_Report_PaymentsMismatch]

@chainID varchar(20),
@PersonID int,
@Banner varchar(50),
@ProductUPC varchar(20),
@SupplierId varchar(10),
@StoreId varchar(10),
@LastxDays int,
@StartDate varchar(20),
@EndDate varchar(20), @MaxRowsCount varchar(20) = ' Top 2500000 '
  
as
Begin
Declare @sqlQuery varchar(4000)
Declare @AttValue int
Declare @CostFormat varchar(10)

	if(@supplierID<>'-1')
		Select @CostFormat = Costformat from SupplierFormat WITH(NOLOCK)  where SupplierID = @supplierID
	 else
		set @CostFormat=4	
		set @CostFormat = ISNULL(@CostFormat , 4)
 	
 select @attvalue = AttributeID  from AttributeValues WITH(NOLOCK)  where OwnerEntityID=@PersonID and AttributeID=17
 
 set @sqlQuery =  ' select distinct P.PaymentId, C.ChainName as [Retailer Name],S.SupplierName as [Supplier Name], 
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
		set @sqlQuery = @sqlQuery + ' and C.ChainID=' + @ChainId
  
	if(@SupplierID <>'-1') 
		set @sqlQuery = @sqlQuery + ' and S.SupplierId=' + @SupplierId

	set @sqlQuery = @sqlQuery + ' Order by P.PaymentId desc '
	
	print(@sqlQuery);
	execute(@sqlQuery); 
			
	End
GO
