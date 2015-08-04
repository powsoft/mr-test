USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_CheckDetailsByTitle_WHLS_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- EXEC [amb_CheckDetailsByTitle_WHLS] 'CLL','24164','DQ','753000'
-- EXEC [amb_CheckDetailsByTitle_WHLS] 'WR1488','24538','DOIL','843503'
-- EXEC [amb_CheckDetailsByTitle_WHLS] 'WR5658','26922','DQ','905049'
-- EXEC [amb_CheckDetailsByTitle_WHLS] 'BG','24143','CF','863877'
-- EXEC [amb_CheckDetailsByTitle_WHLS] 'BG','24143','CF','931929'
-- EXEC [amb_CheckDetailsByTitle_WHLS] 'WR651','26582','CF','920238'
-- EXEC [amb_CheckDetailsByTitle_WHLS] 'WR5658','26922','DQ','964565'
--SELECT * from ##TempPOS

-- EXEC [amb_CheckDetailsByTitle_WHLS_10_02_2014] 'WR5658','26922','DQ','952604'
-- EXEC [amb_CheckDetailsByTitle_WHLS] 'WR5658','26922','CEFCO','879525'
-- EXEC [amb_CheckDetailsByTitle_WHLS] 'WR2470','25036','-1','951207'

-- EXEC [amb_CheckDetailsByTitle_WHLS] 'WR4336','25939','LG','1053524'

-- EXEC [amb_CheckDetailsByTitle_WHLS] 'WR4336','25939','LG','1053524'
CREATE proc [dbo].[amb_CheckDetailsByTitle_WHLS_PRESYNC_20150415]
(
	@wholesalerid varchar(20),
	@SupplierID varchar(20),
	@ChainID varchar(20),
	@CheckNum varchar(40)
)
AS
BEGIN


Declare @SqlNew VARCHAR(8000)
Declare @SqlTemp VARCHAR(8000)


IF object_id('tempdb.dbo.##tempDraws') is not null 
	BEGIN
	  drop table ##tempDraws;
	END
	
SET	@SqlTemp = ' Select distinct ST.ChainID
					, ST.StoreId
					, ST.SupplierID
					, Pd.CheckNo AS CheckNumber
					, dbo.GetWeekEnd_TimeOutFix(ST.SaleDateTime,BC.BillingControlDay) AS WeekEnding
					, P.ProductName AS TitleName
					, P.ProductId
					, Qty,TransactionTypeID
					, datename(W,SaleDateTime)+ ''Draw'' AS [wDay]

				INTO ##tempDraws

				FROM dbo.InvoiceDetails ID  WITH (NOLOCK) 
					INNER JOIN dbo.Storetransactions_Forward ST  WITH (NOLOCK) ON ID.SupplierID=ST.SupplierID AND ID.ChainID=ST.ChainID 
						AND ID.StoreID=ST.StoreID 
						AND ID.ProductID=ST.ProductID 
						AND ID.SaleDate=ST.SaleDateTime
					INNER JOIN (Select distinct DisbursementID, PaymentID, PaymentStatus from dbo.PaymentHistory WITH (NOLOCK)) PH ON ID.PaymentID=PH.PaymentID and PH.PaymentStatus=10
					INNER JOIN dbo.PaymentDisbursements PD  WITH (NOLOCK) ON PD.DisbursementID=PH.DisbursementID and PD.VoidStatus is Null
					INNER JOIN dbo.Chains C  WITH (NOLOCK) on ST.ChainID=C.ChainID 
					INNER JOIN dbo.Products P  WITH (NOLOCK) ON ST.ProductID = P.ProductID
					
					LEFT JOIN (Select distinct ChainId, SupplierId, EntityIDToInvoice, BillingControlDay 
									from DataTrue_Main.dbo.BillingControl WITH (NOLOCK) 
								   ) BC on BC.EntityIDToInvoice=ST.SupplierID and BC.chainid=ST.chainid
					
				Where TransactionTypeID in (29)  and ID.retailerInvoiceID<>0 and ST.SupplierId='+@SupplierID 
				
				IF(@ChainID<>'-1')					
					SET @SqlTemp += ' and C.ChainIdentifier='''+@ChainID+''''
						
				IF(@CheckNum<>'-1')					
					SET @SqlTemp += ' and Pd.CheckNo='''+@CheckNum+''''	
				
				PRINT(@SqlTemp)		
				EXEC(@SqlTemp)		
		
                   
	IF object_id('tempdb.dbo.##tempPOS') is not null
		BEGIN
		   drop table ##tempPOS
		END	
		
	SET	@SqlTemp = 'Select Distinct ST.ChainID
					, ST.StoreId
					, ST.SupplierID
					, Pd.CheckNo AS CheckNumber
					, dbo.GetWeekEnd_TimeOutFix(ST.SaleDateTime,BC.BillingControlDay) AS WeekEnding
					, P.ProductName AS TitleName
					, P.ProductId
					, id.totalQty as Qty
					, id.unitcost as rulecost
					, st.TransactionTypeID
					, cast(st.RuleCost  AS MONEY) AS CostToStore
					, datename(W,SaleDateTime)+ ''POS'' as [POSDay]	

					INTO ##tempPOS								
					FROM dbo.PaymentDisbursements PD
					INNER JOIN (Select distinct DisbursementID, PaymentID, PaymentStatus from dbo.PaymentHistory WITH (NOLOCK)) PH ON PD.DisbursementID = PH.DisbursementID AND PH.PaymentStatus = 10
					INNER JOIN dbo.Payments PY WITH (NOLOCK)
						ON PY.PaymentID = PH.PaymentID 
					INNER JOIN dbo.InvoiceDetails ID WITH (NOLOCK)
						ON ID.PaymentID = PH.PaymentID 
					INNER JOIN (Select ChainId, SupplierID, StoreId, ProductId, ST.TransactionTypeID,SaleDateTime, RuleCost
									from dbo.Storetransactions ST WITH (NOLOCK)	
									INNER JOIN dbo.TransactionTypes TT WITH (NOLOCK)
										ON TT.TransactionTypeID = ST.TransactionTypeID AND TT.BucketType = 1
									group by ChainId, SupplierID, StoreId, ProductId, ST.TransactionTypeID, SaleDateTime, RuleCost
								) ST ON ID.SupplierID = ST.SupplierID AND ID.ChainID = ST.ChainID AND ID.StoreID = ST.StoreID 
						   AND ID.ProductID = ST.ProductID AND ID.SaleDate = ST.SaleDateTime
						
					INNER JOIN dbo.Chains C WITH (NOLOCK)
							ON ST.ChainID = C.ChainID		   
					INNER JOIN dbo.Suppliers S WITH (NOLOCK)
							ON S.SupplierID = ST.SupplierID		
					INNER JOIN dbo.Stores SS  WITH (NOLOCK)
							ON SS.StoreID = ST.StoreID AND SS.ChainID=ST.ChainID		
					INNER JOIN dbo.Products P WITH (NOLOCK)
							ON ST.ProductID = P.ProductID		
					LEFT JOIN (Select distinct ChainId, SupplierId, EntityIDToInvoice, BillingControlDay 
									from DataTrue_Main.dbo.BillingControl WITH (NOLOCK) 
								   )  BC ON BC.EntityIDToInvoice = S.SupplierID AND BC.ChainID = C.ChainID			
					WHERE 1 = 1 and PD.VoidStatus is Null and ID.retailerInvoiceID<>0 AND PY.PayeeEntityID='+@SupplierID
		
					IF(@ChainID<>'-1')					
						SET @SqlTemp += ' and C.ChainIdentifier='''+@ChainID+''''
							
					IF(@CheckNum<>'-1')					
						SET @SqlTemp += ' and Pd.CheckNo='''+@CheckNum+''''
						
					print(@SqlTemp)
					EXEC(@SqlTemp)


	IF object_id('tempdb.dbo.##tempFinalData') is not null
		BEGIN
		   drop table ##tempFinalData
		END	
			
	SET	@SqlTemp = 'SELECT tmpPOS.ChainID
								, tmpPOS.StoreId
								, tmpPOS.SupplierID
								, tmpPOS.CheckNumber
								, tmpPOS.WeekEnding
								, tmpPOS.TitleName
								, tmpPOS.productid
								, tmpPOS.rulecost
								, isnull(tmpPOS.CostToStore,0) AS CostToStore
								, isnull(tmpdraws.MondayDraw, 0) AS MondayDraw
								, isnull(tmpdraws.TuesdayDraw, 0) AS TuesdayDraw
								, isnull(tmpdraws.WednesdayDraw, 0) AS WednesdayDraw
								, isnull(tmpdraws.ThursdayDraw, 0) AS ThursdayDraw
								, isnull(tmpdraws.FridayDraw, 0) AS FridayDraw
								, isnull(tmpdraws.SaturdayDraw, 0) AS SaturdayDraw
								, isnull(tmpdraws.SundayDraw, 0) AS SundayDraw
								, isnull(tmpPOS.MondayPOS, 0) AS MondayPOS
								, isnull(tmpPOS.TuesdayPOS, 0) AS TuesdayPOS
								, isnull(tmpPOS.WednesdayPOS, 0) AS WednesdayPOS
								, isnull(tmpPOS.ThursdayPOS, 0) AS ThursdayPOS
								, isnull(tmpPOS.FridayPOS, 0) AS FridayPOS
								, isnull(tmpPOS.SaturdayPOS, 0) AS SaturdayPOS
								, isnull(tmpPOS.SundayPOS, 0) AS SundayPOS
								, cast(NULL AS NVARCHAR(50)) AS legacySystemStoreIdentifier
								, cast(NULL AS NVARCHAR(50)) AS supplieridentifier
								, cast(NULL AS NVARCHAR(50)) AS ChainIdentifier

						INTO
							##tempFinalData

						FROM
							(SELECT * FROM ##tempPOS
										PIVOT (sum(Qty) FOR POSDay IN (MondayPOS, TuesdayPOS, WednesdayPOS, ThursdayPOS, FridayPOS, SaturdayPOS, SundayPOS)) 
										AS POS_eachday) tmpPOS
										LEFT JOIN 
										(SELECT * FROM ##tempDraws
												PIVOT (sum(Qty) FOR wDay IN ([MondayDraw], TuesdayDraw, WednesdayDraw, ThursdayDraw, FridayDraw, SaturdayDraw, SundayDraw)) 
											 AS Draw_eachday) tmpdraws
												ON tmpdraws.ChainID = tmpPOS.ChainID 
									AND tmpdraws.SupplierID = tmpPOS.SupplierID 
									AND tmpdraws.StoreID = tmpPOS.StoreID 
									AND tmpdraws.ProductID = tmpPOS.ProductID 
									AND tmpdraws.CheckNumber = tmpPOS.CheckNumber 
		
									AND cast(tmpdraws.WeekEnding AS DATE) = cast(tmpPOS.WeekEnding AS DATE) '
		PRINT(@SqlTemp)		
		EXEC(@SqlTemp)

		SET	@SqlTemp = 'UPDATE F SET 

							F.legacySystemStoreIdentifier=(SELECT DISTINCT legacySystemStoreIdentifier FROM dbo.Stores  WHERE StoreID=f.StoreID),
							
							F.ChainIdentifier=(SELECT DISTINCT ChainIdentifier FROM dbo.Chains WHERE ChainId=f.ChainId ),
							
							F.supplieridentifier=(SELECT DISTINCT supplieridentifier FROM dbo.suppliers WHERE supplierid=f.supplierid)					
							
						FROM ##tempFinalData F '
		PRINT(@SqlTemp)		
		EXEC(@SqlTemp)

		SET @SqlNew = 'SELECT ChainIdentifier AS ChainID
												, legacySystemStoreIdentifier AS StoreID
												, supplieridentifier AS WholesalerID
												, CheckNumber
												, WeekEnding
												, TitleName
												, CAST(isnull(mondayPOS,0) AS INT)  AS MonSl
												, CAST(isnull(tuesdayPOS,0) AS INT)  AS TueSl
												, CAST(isnull(wednesdayPOS,0) AS INT)  AS WedSl
												, CAST(isnull(thursdayPOS,0) AS INT)  AS ThurSl
												, CAST(isnull(fridayPOS,0) AS INT)  AS FriSl
												, CAST(isnull(saturdayPOS,0) AS INT)  AS SatSl
												, CAST(isnull(sundayPOS,0) AS INT)  AS SunSl
												, (CAST(isnull(mondayPOS,0) AS INT) + CAST(isnull(tuesdayPOS,0) AS INT) +CAST(isnull(wednesdayPOS,0) AS INT) +CAST(isnull(thursdayPOS,0) AS INT) +CAST(isnull(fridayPOS,0) AS INT) +CAST(isnull(saturdayPOS,0) AS INT) +CAST(isnull(sundayPOS,0) AS INT))  AS [TotalUnits]
												, rulecost AS DeliveryFee												
												, (CAST(isnull(mondayPOS,0) AS INT) + CAST(isnull(tuesdayPOS,0) AS INT) +CAST(isnull(wednesdayPOS,0) AS INT) +CAST(isnull(thursdayPOS,0) AS INT) +CAST(isnull(fridayPOS,0) AS INT) +CAST(isnull(saturdayPOS,0) AS INT) +CAST(isnull(sundayPOS,0) AS INT) )*isnull(rulecost,0) AS Net
												, '''' AS WHLS_StoreID

									 FROM
										 ##tempFinalData
										 
										 UNION ALL
										 
										 Select distinct C.ChainIdentifier AS ChainID
												, legacySystemStoreIdentifier  AS StoreID
												, S.supplieridentifier AS WholesalerID
												, PD.CheckNo CheckNumber
												, dbo.GetWeekEnd_TimeOutFix(SaleDate,BC.BillingControlDay) AS WeekEnding
												, ''Delivery Fee'' TitleName
												, ISNULL(TotalCost,0) as Net
												, 0 AS DeliveryFee
												, 0 AS MonSl
												, 0 AS TueSl
												, 0 AS WedSl
												, 0 AS ThurSl
												, 0 AS FriSl
												, 0 AS SatSl
												, 0 AS SunSl
												, '''' AS WHLS_StoreID
												, 0 AS [TotalUnits]
												
												FROM  dbo.InvoiceDetails ID WITH (NOLOCK)
													JOIN dbo.InvoiceDetailTypes t WITH (NOLOCK)
														ON ID.InvoiceDetailTypeID = t.InvoiceDetailTypeID AND t.InvoiceDetailTypeID=16
													INNER JOIN (Select distinct DisbursementID, PaymentID, PaymentStatus from dbo.PaymentHistory WITH (NOLOCK)
																) PH ON ID.PaymentID=PH.PaymentID and PH.PaymentStatus=10
													INNER JOIN dbo.PaymentDisbursements PD WITH (NOLOCK)
														ON PD.DisbursementID = PH.DisbursementID and PD.VoidStatus is Null
													INNER JOIN dbo.Chains C WITH (NOLOCK)
														ON ID.ChainID = C.ChainID
													INNER JOIN dbo.Stores ST WITH (NOLOCK)
														ON ST.StoreID = ID.StoreID 
													INNER JOIN dbo.Suppliers S WITH (NOLOCK)
														ON S.SupplierID = ID.SupplierID 
													LEFT JOIN DataTrue_Main.dbo.BillingControl BC WITH (NOLOCK) 
														ON BC.EntityIDToInvoice=S.SupplierID and BC.ChainID=C.ChainID
														
										where  ID.SupplierId='+@SupplierID 
								
						IF(@CheckNum<>'-1')					
							SET @SqlNew += ' and Pd.CheckNo='''+@CheckNum+'''	'
				       
			PRINT(@SqlNew)		
			EXEC(@SqlNew)
			
		  	
		-- drop temp tables
		IF object_id('tempdb.dbo.##tempDraws') is not null 
			BEGIN
			  drop table ##tempDraws;
			END
		
		IF object_id('tempdb.dbo.##tempFinalData') is not null
			BEGIN
			   drop table ##tempFinalData
			END	
		IF object_id('tempdb.dbo.##tempPOS') is not null
			BEGIN
			   drop table ##tempPOS
			END	
		
					
END
GO
