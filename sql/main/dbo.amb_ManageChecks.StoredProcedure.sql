USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_ManageChecks]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec amb_ManageChecks '-1','-1','12-14-2012','',''
CREATE  procedure [dbo].[amb_ManageChecks]
 @SupplierId varchar(10),
 @ChainId varchar(10),
 @DisburseDate varchar(15),
 @StartCheckNo varchar(50),
 @BatchNo varchar(50)
as

Begin
Declare @sqlQuery varchar(4000)

	set @sqlQuery = 'select D.DisbursementID, convert(varchar(10),D.DisbursementDate,101) as DisbursementDate, D.CheckNo, D.DisbursementAmount,
					D.BatchNo, S.SupplierName, C.ChainName 
					from PaymentDisbursements D
					inner join PaymentHistory PH on PH.DisbursementID=D.DisbursementId
					inner join Payments P on P.PaymentID=PH.PaymentID
					inner join Suppliers S on S.SupplierID=P.PayeeEntityID
					inner join Chains C on C.ChainID=P.PayerEntityID where 1=1 '							

	if(@ChainId<>'-1') 
		set @sqlQuery = @sqlQuery +  ' and C.ChainID = ' + @ChainId

	if(@SupplierId<>'-1') 
		set @sqlQuery = @sqlQuery +  ' and S.SupplierID = ' + @SupplierId

	if(@DisburseDate<>'1900-01-01') 
		set @sqlQuery = @sqlQuery + ' and D.DisbursementDate = ''' + @DisburseDate + '''';

	If(@StartCheckNo<>'')
		set @sqlQuery = @sqlQuery + ' and D.CheckNo like ''%' + @StartCheckNo + '%'''

	If(@BatchNo<>'')
		set @sqlQuery = @sqlQuery + ' and D.BatchNo like ''%' + @BatchNo + '%'''
    --PRINT (@sqlQuery); 
	exec (@sqlQuery); 

End
GO
