USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_ManageRetailerChecks]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec usp_ManageRetailerChecks '-1','40393','1900-01-01',''
CREATE  procedure [dbo].[amb_ManageRetailerChecks]
 @SupplierId varchar(10),
 @ChainId varchar(10),
 @CheckDate varchar(15),
 @CheckNo varchar(50)
as

Begin
Declare @sqlQuery varchar(4000)

	set @sqlQuery = 'select distinct S.SupplierName as [Supplier Name], C.ChainName as [Retailer Name], PH.PaymentID,
					convert(varchar,PH.DatePaymentReceived,101) as PayDateFromRetailer,
					(PH.CheckNoReceived) as RetailerCheckNumber, PH.AmountPaid
					from Payments P
					inner join PaymentHistory PH on PH.PaymentID=P.PaymentID 	
					inner join Chains C on C.ChainID=P.PayerEntityID
					inner join Suppliers S on S.SupplierID=P.PayeeEntityID
					where PH.PaymentStatus=3'
					
    if(@SupplierId<>'-1') 
		set @sqlQuery = @sqlQuery +  ' and S.SupplierID = ' + @SupplierId												

	if(@ChainId<>'-1') 
		set @sqlQuery = @sqlQuery +  ' and C.ChainID = ' + @ChainId

	if(@CheckDate<>'1900-01-01') 
		set @sqlQuery = @sqlQuery + ' and convert(date,PH.DatePaymentReceived) = convert(date,''' +  @CheckDate + ''')';

	If(@CheckNo<>'')
		set @sqlQuery = @sqlQuery + ' and PH.CheckNoReceived like ''%' + @CheckNo + '%'''

	exec (@sqlQuery); 

End
GO
