USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_ViewRemittanceOldInfoWHL]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- (Mixed) Exec amb_ViewRemittanceOldInfoWHL '-1','','Wr1428','41342'
-- (Mixed) Exec amb_ViewRemittanceOldInfoWHL 'BAM','-1','CLL','24164'

-- (Mixed) Exec amb_ViewRemittanceOldInfoWHL 'DQ','-1','CLL','24164'

-- Exec amb_ViewRemittanceOldInfoWHL 'CF','888427','WR803','26804'

CREATE PROCEDURE [dbo].[amb_ViewRemittanceOldInfoWHL]
    (
      @ChainID VARCHAR(10) ,
      @CheckNum VARCHAR(10) ,
      @WholesalerIdentifier VARCHAR(20),
      @WholesalerId VARCHAR(20)
    )
AS 
BEGIN


	DECLARE @sqlQuerynew VARCHAR(4000)

	/* ------ GET DATA FROM THE NEW DATABASE (DataTrue_Main)-------- */	
	SET @sqlQuerynew =' SELECT Distinct S.SupplierIdentifier AS WholesalerID,
										ST.LegacySystemStoreIdentifier AS StoreID,
										Convert(varchar(12),IR.InvoicePeriodEnd,101) as WeekEnding,
										LEFT(IDT.InvoiceDetailTypeName,3) AS NewInvType,
										--SUM(isnull(PD.DisbursementAmount,0)) AS SumOfTotalCheck,
										SUM(Id.TotalCost) AS SumOfTotalCheck,
										PH.CheckNoReceived AS CheckNumber,
										Convert(varchar(12),PD.DisbursementDate,101) as DateIssued 

					FROM dbo.PaymentDisbursements PD WITH (NOLOCK) 
					   INNER JOIN (Select distinct DisbursementID, PaymentID, PaymentStatus,CheckNoReceived from dbo.PaymentHistory WITH (NOLOCK)) PH ON PD.DisbursementID=PH.DisbursementID
					   INNER JOIN dbo.InvoiceDetails ID  WITH (NOLOCK) ON ID.PaymentID=PH.PaymentID
					   INNER JOIN dbo.InvoiceDetailTypes IDT  WITH (NOLOCK) ON IDT.InvoiceDetailTypeID=ID.InvoiceDetailTypeID
					   INNER JOIN dbo.InvoicesSupplier IR  WITH (NOLOCK) ON IR.SupplierInvoiceID=ID.SupplierInvoiceID
					   INNER JOIN dbo.Suppliers S  WITH (NOLOCK) ON S.SupplierID=ID.SupplierID
					   INNER JOIN dbo.Stores ST  WITH (NOLOCK) ON St.StoreID=ID.StoreID
					   INNER JOIN dbo.Chains C  WITH (NOLOCK) ON C.ChainID=ID.ChainID 
	                     --  Left JOIN dbo.servicefees SF  WITH (NOLOCK) on SF.SupplierID=IR.SupplierID
				   '

	SET @sqlQuerynew += 'Where 1=1 AND PD.VoidStatus is null AND ((ID.SupplierID)=' + @WholesalerId  + ')  AND ((Cast(IR.InvoicePeriodEnd as date)) < Cast(PD.DisbursementDate - 45 AS Date)) '

	IF (@CheckNum <> '' and @CheckNum <> '-1' ) 
		 SET @sqlQuerynew += ' AND PH.CheckNoReceived like ''%' + @CheckNum + '%'''
	   
	IF ( @ChainID <> '-1' ) 
		 SET @sqlQuerynew += ' AND C.ChainIdentifier = ''' + @ChainID + ''''
		 
    SET @sqlQuerynew += ' GROUP BY S.SupplierIdentifier,ID.SupplierID,ST.LegacySystemStoreIdentifier,IR.InvoicePeriodEnd,
					  IDT.InvoiceDetailTypeName,PH.CheckNoReceived,PD.DisbursementDate,C.ChainIdentifier 
					  ORDER BY S.SupplierIdentifier, ST.LegacySystemStoreIdentifier  , LEFT(IDT.InvoiceDetailTypeName,3);'

    EXEC(@sqlQuerynew) 
    Print(@sqlQuerynew) 

END
GO
