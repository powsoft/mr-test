USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_ViewCheckDetailsWHL]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
---- EXEC amb_ViewCheckDetailsWHL 'ENT','24178','11/11/2012','109220',''
---- EXEC amb_ViewCheckDetailsWHL 'CLL','24164','1900/01/01','764846','DQ'

---- EXEC amb_ViewCheckDetailsWHL 'WR1488','24538','1900/01/01','843503','DOIL'
---- EXEC amb_ViewCheckDetailsWHL 'WR1055','28542','2013/12/08','803219','LG'
---- EXEC amb_ViewCheckDetailsWHL 'HNA','28792','1900/01/01','867233','CF'
---- EXEC amb_ViewCheckDetailsWHL 'WR651','26582','1900/01/01','920238','CF'
---- EXEC amb_ViewCheckDetailsWHL 'WR857','27131','1900/01/01','974683','-1'


CREATE PROCEDURE [dbo].[amb_ViewCheckDetailsWHL]
	 @WholesalerIdentifier VARCHAR(20)
	,@WholesalerId varchar(20)
	,@weekend VARCHAR(20)
	,@checknumber VARCHAR(30)
	,@ChainID varchar(20)

AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @SqlNewDb varchar(max)
	
	SET @SqlNewDb ='SELECT s.SupplierIdentifier AS WholesalerID
							 , t.InvoiceDetailTypeName AS InvType
							 , c.ChainIdentifier AS ChainID
							 , convert(VARCHAR(12), inv.InvoicePeriodEnd, 101) AS WeekEnding
							 , sum(ISNULL(i.TotalCost,0))-sum(ISNULL(Adjustment1,0))   AS SumOfTotalCheck
							 , convert(VARCHAR(12), d.DisbursementDate, 101) AS DateIssued
							 , convert(VARCHAR, d.CheckNo) AS CheckNumber

					FROM
						dbo.InvoicesSupplier inv WITH (NOLOCK) 
						JOIN dbo.InvoiceDetails i WITH (NOLOCK) 
							ON inv.SupplierInvoiceID = i.SupplierInvoiceID 
								AND RetailerInvoiceID<>0
						JOIN dbo.Payments p WITH (NOLOCK) 
							ON i.PaymentID = p.PaymentID
						JOIN (Select distinct DisbursementID, PaymentID, PaymentStatus from dbo.PaymentHistory WITH (NOLOCK))  h 
							ON p.PaymentID = h.PaymentID AND h.PaymentStatus = 10
						JOIN dbo.PaymentDisbursements d WITH (NOLOCK) 
							ON h.DisbursementID = d.DisbursementID and d.VoidStatus is null
						JOIN dbo.Suppliers s WITH (NOLOCK) 
							ON inv.SupplierID = s.SupplierID
						JOIN dbo.Chains c WITH (NOLOCK) 
							ON i.ChainID = c.ChainID
						JOIN dbo.InvoiceDetailTypes t WITH (NOLOCK) 
							ON i.InvoiceDetailTypeID = t.InvoiceDetailTypeID
                            
					WHERE
						1 = 1 AND inv.SupplierID='+@WholesalerId 
	
	IF (CAST(@weekend AS DATE) <> CAST('1900-01-01' AS DATE))
		set @SqlNewDb = @SqlNewDb +' and Inv.InvoicePeriodEnd  = ''' + convert(varchar, +@weekend,101) +  ''''
		
  IF (@ChainID<>'-1')
		set @SqlNewDb=@SqlNewDb + ' AND C.ChainIdentifier=''' + @ChainID + ''''
		
	IF (@checknumber<>'-1')
		SET @SqlNewDb = @SqlNewDb + ' AND d.CheckNo = ''' + @CheckNumber + ''''
	set @SqlNewDb = @SqlNewDb + ' GROUP BY
																s.SupplierIdentifier
															, t.InvoiceDetailTypeName
															, c.ChainIdentifier
															, convert(VARCHAR(12), inv.InvoicePeriodEnd, 101)
															, convert(VARCHAR(12), d.DisbursementDate, 101),
																CONVERT(VARCHAR,d.CheckNo)
																
																'
	print(@SqlNewDb);   
	Exec(@SqlNewDb);   
END
GO
