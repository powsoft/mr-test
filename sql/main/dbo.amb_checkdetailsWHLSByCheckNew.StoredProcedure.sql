USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_checkdetailsWHLSByCheckNew]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- alter date: <alter Date,,>
-- Description:	<Description,,>
-- =============================================

--exec [dbo].[amb_checkdetailsWHLSByCheckNew] 'WR320','271248'
--exec [dbo].[amb_checkdetailsWHLSByCheckNew] 'WR320','273490'
--exec [dbo].[amb_checkdetailsWHLSByCheckNew] 'Wolfe','370808'
--exec [dbo].[amb_checkdetailsWHLSByCheckNew] 'WR2198','104865'
--SELECT * FROM Suppliers where SupplierIdentifier='CLL'

--exec amb_checkdetailsWHLSByCheckNew 'CLL','24164','753000','753000'

CREATE PROCEDURE [dbo].[amb_checkdetailsWHLSByCheckNew]

	@WholesalerIdentifier VARCHAR(20),
	@WholesalerID VARCHAR(20),
	@checknumber VARCHAR(30),
	@checknumber2 VARCHAR(30)
	
AS


Declare @SqlNew VARCHAR(8000)
BEGIN
SET NOCOUNT ON;
SET @SqlNew = 'select  WholesalerID
		, CheckNumber
		,  ChainID
		, [Store Number]
		,  [NewspaperName]
		, sum(SumOfQnt) as SumOfQnt
		, cast(CostToStore as FLOAT) as CostToStore
		, cast(sum(TotalCost) as FLOAT) as TotalCost
		, DateIssued
		, Convert(varchar(12),weekEnd ,101) as EndWeek
		, InvType
		,  TitleID 
		from
		(
			SELECT DISTINCT S.SupplierIdentifier AS WholesalerID
							, Pd.CheckNo AS CheckNumber
							, C.ChainIdentifier AS ChainID
							, ID.StoreIdentifier AS [Store Number]
							, P.ProductName AS [NewspaperName]
							, Id.TotalQty AS SumOfQnt
							, isnull(Id.Unitcost,0) AS CostToStore
							, (ID.TotalQty * Id.Unitcost) AS TotalCost
							, convert(VARCHAR, PD.DisbursementDate, 101) AS DateIssued
							, (SELECT top 1 dateadd(dd, BillingControlDay - (datepart (dw, (ID.SaleDate))), ID.SaleDate)
								 FROM
									 BillingControl BC where  BC.ChainID =id.ChainID and BC.EntityIDToInvoice=ID.SupplierID) as weekEnd
							, IDT.InvoiceDetailTypeName AS InvType
							, PID.Bipad AS TitleID
					FROM
						DataTrue_Report.dbo.InvoiceDetails ID
						INNER JOIN dbo.PaymentHistory PH
							ON ID.PaymentID = PH.PaymentID AND PH.PaymentStatus = 10
						INNER JOIN DataTrue_Report.dbo.PaymentDisbursements PD
							ON PD.DisbursementID = PH.DisbursementID
						INNER JOIN DataTrue_Report.dbo.InvoiceDetailTypes IDT
							ON ID.InvoiceDetailTypeID = IDT.InvoiceDetailTypeID
						INNER JOIN DataTrue_Report.dbo.Chains C
							ON ID.ChainID = C.ChainID
						INNER JOIN dbo.chains_migration Cm
							ON Cm.chainid = C.ChainIdentifier
						INNER JOIN DataTrue_Report.dbo.Suppliers S
							ON S.SupplierID = ID.SupplierID
						INNER JOIN DataTrue_Report.dbo.Products P
							ON ID.ProductID = P.ProductID
						LEFT JOIN DataTrue_Report.dbo.ProductIdentifiers PID
							ON PID.OwnerEntityID = ID.SupplierID AND PID.Productidentifiertypeid = 8
							where 1=1 

						AND ID.SupplierID=' + @WholesalerID
										
    IF (@checknumber<>'')
			SET @SqlNew += ' AND Pd.CheckNo >=''' + @checknumber + ''''
	
    IF (@checknumber2<>'')
			SET @SqlNew += ' AND Pd.CheckNo <= ''' + @checknumber2 + ''''
		
		
		SET @SqlNew += ') a
				GROUP BY
						weekEnd
					, WholesalerID
					, CheckNumber
					, ChainID
					, [Store Number]
					, [NewspaperName]
					, CostToStore
					, DateIssued
					, weekEnd
					, InvType
					, TitleID '
					
	Print @SqlNew
EXEC (@SqlNew)

END
GO
