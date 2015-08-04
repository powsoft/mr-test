USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GenerateDisbursementDataForPeechTree]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec usp_GenerateDisbursementDataForPeechTree '-1','42491','-1','','10','1900-01-01','1900-01-01','-1','',''
CREATE  procedure [dbo].[usp_GenerateDisbursementDataForPeechTree]
(
	@SupplierId varchar(20),
	@ChainId varchar(20),
	@Custom1 varchar(255),
	@StoreId varchar(20),
	@Status varchar(20),
	@StartDate varchar(50),
	@EndDate  varchar(50),
	@InvoiceType varchar(50),
	@StartCheckNo varchar(50),
	@EndCheckNo varchar(50)
)
as

Begin
	Declare @sqlQuery varchar(4000) 
	DECLARE @sqlWhere VARCHAR(5000)

	Set @sqlWhere=''
	
	set @sqlQuery ='SELECT DISTINCT S.SupplierIdentifier AS VendID,
					S.SupplierName AS Expr1001,
					S.SupplierName AS  WholesalerName,S.SupplierID, 
					A.Address1 AS [ADDRESS], A.City AS City,A.State AS [STATE],A.PostalCode AS ZipCode,
					convert(varchar,DisbursementDate,101) as [Today Date],
					PD.CheckNo AS CheckNumber,PD.DisbursementAmount AS SumOfTotalCheck, 
					cast(S.SupplierIdentifier as varchar) + ''_'' + cast(C.ChainIdentifier as varchar) AS [ColumnA_ChainID] 
					from PaymentDisbursements PD
					inner join PaymentHistory PH on PH.DisbursementID=PD.DisbursementID
					inner join Payments P on P.PaymentID=PH.PaymentID
					inner join Suppliers S on S.SupplierID=P.PayeeEntityID
					inner join Chains c on C.chainid=P.PayerEntityID
					Left JOIN dbo.Addresses A on A.ownerentityid=S.SupplierID
					Where 1=1 '
 
	If(@StartCheckNo<>'')
		set @sqlWhere = @sqlWhere + ' and PD.Checkno >= ' + @StartCheckNo 
		
	If(@EndCheckNo<>'')
		set @sqlWhere = @sqlWhere + ' and PD.Checkno <= ' + @EndCheckNo 
		
	if(@SupplierId <>'-1')
		set @sqlWhere = @sqlWhere + ' and P.PayeeEntityID= ' + @SupplierId
		
	if(@ChainId<>'-1')
		set @sqlWhere = @sqlWhere + ' and P.PayerEntityID= ' + @ChainId      

	if(@Status <>'-1')
		set @sqlWhere = @sqlWhere + ' and P.PaymentStatus='+ @Status
	
	if(@Status = '10' or @Status = '11')
		set @sqlWhere = @sqlWhere + '  and  PD.CheckNo is not null 		'
	
	set @sqlQuery = @sqlQuery + @sqlWhere     
	
	exec(@sqlQuery);
End
GO
