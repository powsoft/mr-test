USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_ViewPaymentWHLS_bkup]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--select * from chains_migration
-- exec amb_ViewPaymentWHLS 'DQ','08/25/2013','','CLL','24164'
-- exec amb_ViewPaymentWHLS 'TA','01/01/1900','','WR1428','41342'
create procedure [dbo].[amb_ViewPaymentWHLS_bkup]
(
	@ChainID varchar(10),
	@WeekEnd varchar(20),
	@StoreNumber varchar(10),
	@SupplierIdentifier varchar(20),
	@SupplierId varchar(20)
)

AS 

BEGIN
	Declare @sqlQueryFinal varchar(8000)
	Declare @sqlQueryLegacy varchar(8000)
	Declare @sqlQueryNew varchar(8000)
	Declare @DBType int --0 from old database,1 from new database, 2 from mixed
	DECLARE @chain_migrated_date date
	
	IF(@ChainID<>'-1' AND @WeekEnd<>  CAST('01/01/1900' as DATE))
		BEgin
			SELECT  @chain_migrated_date = cast(datemigrated as VARCHAR) 
			FROM   dbo.chains_migration 
			WHERE  chainid = @ChainID;
			print @chain_migrated_date
			print 'here'
			IF(CAST(@chain_migrated_date as DATE) > CAST('01/01/1900' as DATE))
				BEGIN
					if(@Weekend='1900-01-01')
						BEGIN
							SET @DBType=2
						END
					ELSE
						BEGIN
							IF(CAST(@Weekend as DATE) >= CAST(@chain_migrated_date as DATE))
								BEGIN
									print '1'
									 SET @DBType=2
								END
							ELSE 
								BEGIN
								print '2'
									 SET @DBType=0
								END
						END 
				END
			ELSE
				BEGIN
				print 'there'
					SET @DBType=0
				END
		END
	ELSE
		BEGIN
			 SET @DBType=2
		END
		
		
		print @DBType

/* (Step 1) Get Data from the Old Database (iControl) */
IF (@DBType=0 or @DBType=2)
		BEGIN			
			SET @sqlQueryLegacy='SELECT Distinct I.WholesalerID,SL.ChainID,Convert(datetime,I.WeekEnding,101) as WeekEnding,
								Convert(datetime,PI.DateIssued,101) as DateIssued,
								PI.CheckNumber,I.StoreID,Sum(I.NetInvoice) AS SumOfTotalCheck, 
								I.InvType 
								FROM ( [IC-HQSQL2].iControl.dbo.PaymentIssued  PI RIGHT JOIN 
								  [IC-HQSQL2].iControl.dbo.Invoices I  ON (PI.WholesalerID = I.WholesalerID)							
								AND (PI.WeekEnding = I.WeekEnding) 
								AND (PI.InvNo = I.InvoiceNo)) 
								INNER JOIN  [IC-HQSQL2].iControl.dbo.StoresList  SL ON I.StoreID = SL.StoreID

								GROUP BY I.WholesalerID,SL.ChainID,I.WeekEnding, 
								PI.DateIssued,PI.CheckNumber,I.StoreID,I.InvType ' 

			SET @sqlQueryLegacy +=  ' HAVING 1=1 AND I.WholesalerID=''' + @SupplierIdentifier + ''''

			IF(@ChainID<>'-1')
					SET @sqlQueryLegacy +=  ' AND SL.ChainID = ''' + @ChainID+''''
					
			IF(cast(@WeekEnd as date) <> cast('1900-01-01' as date))
					SET @sqlQueryLegacy += ' AND I.WeekEnding = ''' +  CONVERT(varchar,+@WeekEnd,101)+''''
					
			IF(@StoreNumber<>'')
					SET @sqlQueryLegacy +=  ' AND I.StoreID like ''%'+@StoreNumber+'%'''
		END


/* (Step 2) Get Data from the New Database (DataTrue_Main) */
IF (@DBType=1 or  @DBType=2) 
	BEGIN 
		SET @sqlQueryNew=' SELECT Distinct  sup.SupplierIdentifier as WholesalerID, c.ChainIdentifier as ChainID,
							Convert(datetime,ISP.InvoicePeriodEnd,101) as WeekEnding,Convert(datetime,pd.DisbursementDate,101) as DateIssued, 
							pd.CheckNo AS CheckNumber,s.LegacySystemStoreIdentifier AS StoreID, Sum(ISNULL(p.amountpaid,0)) AS SumOfTotalCheck, 
							idt.InvoiceDetailTypeName AS InvType
							
							FROM dbo.InvoiceDetails ID
							INNER JOIN dbo.InvoiceDetailTypes IDT on id.InvoiceDetailTypeID=idt.InvoiceDetailTypeID
							INNER JOIN dbo.InvoicesSupplier ISP ON ISP.SupplierInvoiceID=id.SupplierInvoiceID
							INNER JOIN dbo.PaymentHistory P ON ID.PaymentID=p.PaymentID and P.PaymentStatus=10
							INNER JOIN dbo.PaymentDisbursements pd ON p.DisbursementID=pd.DisbursementID
							INNER JOIN dbo.Suppliers sup ON sup.SupplierID=id.SupplierID
							INNER JOIN dbo.Chains c ON c.ChainID=id.ChainID 
							INNER JOIN dbo.Stores s ON s.StoreID=id.StoreID

							GROUP BY p.PaymentID,sup.SupplierIdentifier,c.ChainIdentifier ,ISP.InvoicePeriodEnd,ID.SupplierId,
							idt.InvoiceDetailTypeName, s.LegacySystemStoreIdentifier , pd.DisbursementDate,pd.CheckNo ' 

		SET @sqlQueryNew += ' HAVING 1=1  AND ID.SupplierId=' + @SupplierId 
						
		IF(@ChainID<>'-1')
				SET @sqlQueryNew += ' AND C.ChainIdentifier = ''' + @ChainID+''''

		IF(CAST( @WeekEnd as DATE) <> CAST( '1900-01-01' as DATE))
				SET @sqlQueryNew += ' AND convert(varchar,ISP.InvoicePeriodEnd,101) = ''' + CONVERT(varchar,+ @WeekEnd,101)+''''

		IF(@StoreNumber<>'')
				SET @sqlQueryNew += ' AND s.LegacySystemStoreIdentifier like ''%'+@StoreNumber+'%'''

	END
/* ---- Final Query Exec -----*/

	IF(@DBType=2)
		BEGIN		
			SET @sqlQueryFinal=@sqlQueryLegacy + ' UNION ' + @sqlQueryNew		
			set @sqlQueryFinal=@sqlQueryFinal+ ' ORDER BY CheckNumber Desc, StoreID, InvType'
			print (@sqlQueryFinal)
			EXEC(@sqlQueryFinal)			
		END
	ELSE IF(@DBType=1)
		BEGIN	
		set @sqlQueryNew=@sqlQueryNew+ ' ORDER BY CheckNumber Desc, StoreID, InvType'
		EXEC(@sqlQueryNew)	
		
		END
	ELSE IF(@DBType=0)
		BEGIN		
		set @sqlQueryLegacy=@sqlQueryLegacy+ ' ORDER BY CheckNumber Desc, StoreID, InvType'
		print @sqlQueryLegacy
		EXEC(@sqlQueryLegacy)		
	END		
END
GO
