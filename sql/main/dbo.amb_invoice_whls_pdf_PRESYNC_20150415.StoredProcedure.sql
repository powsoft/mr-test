USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_invoice_whls_pdf_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- alter date: <alter Date,,>
-- Description:	<Description,,>
-- =============================================

-- EXEC [amb_invoice_whls_pdf] '0','137197863 ','CLL','24164','BAM'
-- EXEC [amb_invoice_whls_pdf] '0','698968','WR1488','24538','DOIL'

-- EXEC [amb_invoice_whls_pdf] '0','1360274','WR3212','25391','MAV'



CREATE PROCEDURE [dbo].[amb_invoice_whls_pdf_PRESYNC_20150415]
	@DCR varchar(50),
	@InvoiceNo varchar(50),
	@uname varchar(10),
	@SupplierID varchar(20),
	@ChainID varchar(20)
	
AS
BEGIN
	Declare @sqlDrawsOld varchar(4000)
	Declare @sqlReturnsOld varchar(4000)
	Declare @sqlInvoiceOld varchar(4000)
	Declare @SqlDrawsNew VARCHAR(8000)
	Declare @SqlReturnsNew VARCHAR(8000)
	Declare @sqlInvoiceNew varchar(4000)
	Declare @SqlFinal VARCHAR(8000)
	Declare @SqlTemp VARCHAR(8000)
	 
	 IF(@DCR='0')
		BEGIN
			SET  @sqlDrawsOld=' SELECT Distinct I.InvoiceNo, OnR.WholesalerID,Convert(varchar(12),I.WeekEnding,101) as WeekEnding, 
							P.TitleName as TitleName, OnR.Mon, OnR.Tue, OnR.Wed, OnR.Thur, OnR.Fri, OnR.Sat, OnR.Sun, OnR.MonS, OnR.TueS, OnR.WedS, OnR.ThurS, OnR.FriS,OnR.SatS, OnR.SunS, OnR.CostToStore, OnR.SuggRetail, OnR.CostToStore4Wholesaler, OnR.CostToWholesaler, SL.StoreName,SL.ChainID,SL.Address,SL.City,SL.State,SL.ZipCode,SL.StoreNumber,SL.StoreID	
											
							FROM  [IC-HQSQL2].iControl.dbo.Invoices  I 
							 INNER JOIN   [IC-HQSQL2].iControl.dbo.OnR OnR  
							 INNER JOIN [IC-HQSQL2].iControl.dbo.Products P ON OnR.Bipad = P.Bipad ON OnR.WeekEnding = I.WeekEnding
							 AND I.StoreID = OnR.StoreID						 
							 INNER JOIN [IC-HQSQL2].iControl.dbo.StoresList SL ON OnR.StoreID = SL.StoreID
							 INNER JOIN  [IC-HQSQL2].iControl.dbo.ChainsList CL ON SL.ChainID = CL.ChainID  '
							 
			SET  @sqlDrawsOld=  @sqlDrawsOld+' WHERE InvoiceNo = '''+ @InvoiceNo +''' and OnR.WholesalerID='''+@uname+''' and CL.ChainID='''+@ChainID+''''
		
		END
	 ELSE
		BEGIN
		   SET @sqlDrawsOld='SELECT Distinct I.InvoiceNo,OnR.WholesalerID,Convert(varchar(12),I.WeekEnding,101) as WeekEnding,
		                P.TitleName as TitleName,
						[monr]-[monph] AS Mon, [tuer]-[tueph] AS Tue, [wedr]-[wedph] AS Wed, [thurr]-[thurph] AS Thur, [frir]-[friph] AS Fri, 
						[satr]-[satph] AS Sat, [sunr]-[sunph] AS Sun, OnR.MonS, OnR.TueS, OnR.WedS, OnR.ThurS, OnR.FriS, OnR.SatS, OnR.SunS, 
						OnR.CostToStore, OnR.SuggRetail, OnR.CostToStore4Wholesaler, OnR.CostToWholesaler, SL.StoreName, SL.ChainID, 
						SL.Address, SL.City, SL.State, SL.ZipCode, SL.StoreNumber, SL.StoreID 
						
						FROM ( [IC-HQSQL2].iControl.dbo.Invoices I
						     INNER JOIN (  [IC-HQSQL2].iControl.dbo.OnR OnR  
						     INNER JOIN [IC-HQSQL2].iControl.dbo.Products P ON OnR.Bipad = P.Bipad) ON (I.StoreID = OnR.StoreID) 
						     AND (I.WeekEnding = OnR.WeekEnding)) 
						     INNER JOIN [IC-HQSQL2].iControl.dbo.StoresList  SL ON OnR.StoreID = SL.StoreID 
						     INNER JOIN  [IC-HQSQL2].iControl.dbo.ChainsList CL ON SL.ChainID = CL.ChainID '
						     
			SET  @sqlDrawsOld=  @sqlDrawsOld+' WHERE InvoiceNo  = '''+ @InvoiceNo +''' and OnR.WholesalerID='''+@uname+''' and CL.ChainID='''+@ChainID+'''
			 AND OnR.PhysicalCount=1 '
			
		END

	 
	SET @sqlInvoiceOld='SELECT I.InvoiceNo,I.DeliveryFee FROM  [IC-HQSQL2].iControl.dbo.Invoices I  WHERE I.InvoiceNo = '''+ @InvoiceNo +''''
	
	  
	  
	  
   SET @sqlReturnsOld='	SELECT Distinct SL.StoreID,OnR.CreditesOnInvoice,OnR.WholesalerID,P.TitleName as TitleName,OnR.MonR,OnR.TueR,OnR.WedR, 
					OnR.ThurR, OnR.FriR, OnR.SatR, OnR.SunR, MonPh,TuePh,WedPh,ThurPh,FriPh,SatPh,SunPh,PhysicalCount, OnR.CostToStore,OnR.SuggRetail 
					
					FROM ( [IC-HQSQL2].iControl.dbo.OnR OnR   
					INNER JOIN [IC-HQSQL2].iControl.dbo.Products P ON OnR.Bipad = P.Bipad) 
					INNER JOIN [IC-HQSQL2].iControl.dbo.StoresList  SL ON OnR.StoreID = SL.StoreID 
					INNER JOIN  [IC-HQSQL2].iControl.dbo.ChainsList CL ON SL.ChainID = CL.ChainID  
					WHERE CreditesOnInvoice = '''+ @InvoiceNo +''' and OnR.WholesalerID='''+@uname+''' and CL.ChainID='''+@ChainID+'''' 
					--ORDER BY P.AbbrvName ;'
	
	
	IF object_id('tempdb.dbo.##tempDraws') is not null 
	BEGIN
	  drop table ##tempDraws;
	END
	-- SELECT * FROM ##tempFinalData
SET	@SqlTemp = ' Select distinct ST.ChainID
								,ST.StoreId
								,ST.SupplierID
								,dbo.GetWeekEnd_TimeOutFix(ID.SaleDate, BC.BillingControlDay) AS WeekEnding
								,ID.SupplierInvoiceID AS InvoiceNo
								,P.ProductName AS TitleName
								,P.ProductId
								,Qty
								,TransactionTypeID
								,datename(W,SaleDateTime)+ ''Draw'' AS [wDay]

				INTO ##tempDraws

				FROM dbo.InvoiceDetails ID with (nolock) 
				INNER JOIN dbo.Storetransactions_Forward ST  with (nolock) ON ID.SupplierID=ST.SupplierID 
				AND ID.ChainID=ST.ChainID 
				AND ID.StoreID=ST.StoreID 
				AND ID.ProductID=ST.ProductID 
				AND ID.SaleDate=ST.SaleDateTime
				INNER JOIN dbo.Chains C  with (nolock) on ST.ChainID=C.ChainID 
				INNER JOIN dbo.Products P  with (nolock) ON ST.ProductID = P.ProductID
				INNER JOIN  dbo.Addresses A  with (nolock) ON A.OwnerEntityID=ST.StoreID 
				LEFT JOIN DataTrue_Main.dbo.BillingControl BC WITH (NOLOCK) ON BC.EntityIDToInvoice = ID.SupplierID AND BC.ChainID = C.ChainID
				
				
				Where TransactionTypeID in (29)  and ST.SupplierId=' + @SupplierID + ' and ID.SupplierInvoiceID = '''+@InvoiceNo+''' and  C.ChainIdentifier = ''' +@ChainID+''''	
print(@SqlTemp)								
EXEC(@SqlTemp)			
                   
IF object_id('tempdb.dbo.##tempPOS') is not null
		BEGIN
		   drop table ##tempPOS
		END	
		
SET	@SqlTemp = 'Select  ST.ChainID
							   ,ST.StoreId
							   ,ST.SupplierID
							   , dbo.GetWeekEnd_TimeOutFix(ID.SaleDate, BC.BillingControlDay)  AS WeekEnding
							   ,ID.SupplierInvoiceID AS InvoiceNo
							   ,P.ProductName AS TitleName
							   ,P.ProductId
							   ,Qty
							   ,st.TransactionTypeID
							   ,datename(W,SaleDateTime)+ ''POS'' as [POSDay]	
								
				INTO ##tempPOS								

				FROM dbo.InvoiceDetails ID  with (nolock)
				INNER JOIN dbo.Storetransactions ST  with (nolock) ON ID.SupplierID=ST.SupplierID 
								AND ID.ChainID=ST.ChainID 
								AND ID.StoreID=ST.StoreID 
								AND ID.ProductID=ST.ProductID 
								AND ID.SaleDate=ST.SaleDateTime
				INNER JOIN dbo.TransactionTypes TT   with (nolock) on TT.TransactionTypeID=ST.TransactionTypeID AND TT.BucketType=1 
				INNER JOIN dbo.Chains C  with (nolock) on ST.ChainID=C.ChainID
				INNER JOIN dbo.Products P  with (nolock) ON	ST.ProductID = P.ProductID
				INNER JOIN  dbo.Addresses A  with (nolock) ON A.OwnerEntityID=ST.StoreID 
				LEFT JOIN DataTrue_Main.dbo.BillingControl BC WITH (NOLOCK) ON BC.EntityIDToInvoice = ID.SupplierID AND BC.ChainID = C.ChainID
					 										
				WHERE 1 = 1 AND ST.SupplierId='+@SupplierID + ' and ID.SupplierInvoiceID ='''+@InvoiceNo+''' and C.ChainIdentifier ='''+@ChainID+''''
	print(@SqlTemp)
EXEC(@SqlTemp)


IF object_id('tempdb.dbo.##tempFinalData') is not null
		BEGIN
		   drop table ##tempFinalData
		END	
		
SET	@SqlTemp = 'Select distinct tmpPOS.ChainID,
				tmpPOS.StoreId,
				tmpPOS.SupplierID,
				tmpPOS.WeekEnding,
				tmpPOS.InvoiceNo,
				tmpPOS.TitleName,
				tmpPOS.productid,
				ISNULL(tmpdraws.MondayDraw,0) AS MondayDraw,ISNULL(tmpdraws.TuesdayDraw,0) AS TuesdayDraw,ISNULL(tmpdraws.WednesdayDraw,0) AS WednesdayDraw,
				ISNULL(tmpdraws.ThursdayDraw,0) AS ThursdayDraw,ISNULL(tmpdraws.FridayDraw,0) AS FridayDraw,ISNULL(tmpdraws.SaturdayDraw,0) AS SaturdayDraw,
				ISNULL(tmpdraws.SundayDraw,0) AS SundayDraw,ISNULL(tmpPOS.MondayPOS,0) AS MondayPOS,ISNULL(tmpPOS.TuesdayPOS,0) AS TuesdayPOS,
				ISNULL(tmpPOS.WednesdayPOS,0) AS WednesdayPOS,ISNULL(tmpPOS.ThursdayPOS,0) AS ThursdayPOS,ISNULL(tmpPOS.FridayPOS,0) AS FridayPOS,
				ISNULL(tmpPOS.SaturdayPOS,0) AS SaturdayPOS,ISNULL(tmpPOS.SundayPOS,0) AS SundayPOS,
				CAST(NULL as MONEY) AS CostToStore,
				CAST(NULL as MONEY) AS SuggRetail,
				CAST(NULL as nvarchar(50)) as StoreName,
				CAST(NULL as nvarchar(50)) as StoreNumber,
				CAST(NULL as nvarchar(100)) as Address,
				CAST(NULL as nvarchar(50)) as City,
				CAST(NULL as nvarchar(50)) as State,
				CAST(NULL as nvarchar(50)) as ZipCode,
				CAST(NULL as nvarchar(50)) as legacySystemStoreIdentifier,
				CAST(NULL as nvarchar(50)) as supplieridentifier,
				CAST(NULL as nvarchar(50)) as ChainIdentifier
						
				INTO ##tempFinalData
				
				FROM
				( select * FROM
					(SELECT * FROM ##tempPOS) P
					 PIVOT( sum(Qty) FOR  POSDay in ( MondayPOS,TuesdayPOS,
					 WednesdayPOS,ThursdayPOS,FridayPOS,SaturdayPOS,SundayPOS)) AS POS_eachDay
				) tmpPOS 
				left JOIN
				(SELECT * FROM 
					(SELECT * FROM ##tempDraws ) D
					 PIVOT(SUM(Qty) FOR  wDay in
					  (MondayDraw,TuesdayDraw,WednesdayDraw,ThursdayDraw,
					  FridayDraw,SaturdayDraw,SundayDraw)) AS Draw_eachDay
				) tmpdraws	
				ON  tmpdraws.chainid=tmpPOS.chainid
				AND tmpdraws.supplierid=tmpPOS.supplierid
				AND tmpdraws.storeid=tmpPOS.storeid
				AND tmpdraws.productid=tmpPOS.productid '
print(@SqlTemp)					
EXEC(@SqlTemp)


SET	@SqlTemp = 'UPDATE F SET 

					F.costtostore=(SELECT DISTINCT  UnitPrice  FROM dbo.ProductPrices With(NOLOCK) WHERE ProductID=f.productid 
									AND ChainID=f.chainid and StoreID=f.storeid	AND SupplierID=f.supplierid and ProductPriceTypeID=3 and GetDate()  Between ActiveStartDate and ActiveLastDate), 
					
					F.SuggRetail=(SELECT DISTINCT  UnitRetail  FROM dbo.ProductPrices With(NOLOCK) WHERE ProductID=F.productid 
					              AND ChainID=F.chainid and StoreID=F.storeid and supplierid=f.supplierid  and GetDate()  Between ActiveStartDate and ActiveLastDate),
									
					F.legacySystemStoreIdentifier=(SELECT DISTINCT legacySystemStoreIdentifier FROM dbo.Stores With(NOLOCK) WHERE StoreID=f.StoreID),
					
					F.ChainIdentifier=(SELECT DISTINCT ChainIdentifier FROM dbo.Chains With(NOLOCK) WHERE ChainId=f.ChainId ),
					
					F.supplieridentifier=(SELECT DISTINCT supplieridentifier FROM dbo.suppliers With(NOLOCK) WHERE supplierid=f.supplierid),
					              
					F.StoreName=(select distinct StoreName from dbo.Stores  With(NOLOCK) where StoreID=f.StoreID),
					
				    F.StoreNumber=(select distinct StoreIdentifier from dbo.Stores With(NOLOCK) where StoreID=F.StoreID),
				
				    F.address=(select distinct Address1 from dbo.Addresses With(NOLOCK) where OwnerEntityID=F.StoreID),
				    
				    F.city=(select distinct city from dbo.Addresses With(NOLOCK) where OwnerEntityID=F.StoreID),
				    
				    F.state=(select distinct state from dbo.Addresses With(NOLOCK) where OwnerEntityID=F.StoreID),
				    
				    F.zipcode=(select distinct PostalCode from dbo.Addresses With(NOLOCK) where OwnerEntityID=f.StoreID)              				
					
			    FROM ##tempFinalData F '
				    
print(@SqlTemp)
EXEC(@SqlTemp)


SET @SqlDrawsNew = 'SELECT Distinct InvoiceNo,supplieridentifier AS WholesalerID,WeekEnding,TitleName,
				   mondaydraw AS Mon,tuesdaydraw AS Tue,wednesdaydraw AS Wed,thursdaydraw AS Thur,fridaydraw AS Fri,saturdaydraw AS Sat,sundaydraw AS Sun,
				   0 AS MonS, 0 AS TueS, 0 AS WedS, 0 AS ThurS, 0 AS FriS, 0 AS SatS, 0 AS SunS,costtostore,SuggRetail,0 AS CostToStore4Wholesaler,
				   0 AS CostToWholesaler,StoreName,ChainIdentifier AS ChainID,Address,City,State,ZipCode,StoreNumber,legacySystemStoreIdentifier AS StoreId

				   FROM  ##tempFinalData  '
	
	
SET @sqlInvoiceNew ='SELECT ISup.SupplierInvoiceID AS InvoiceNo
							,isnull(dbo.[GetServiceFee](ID.ChainID,ID.SupplierID,ID.StoreID,''-1''),0) AS DeliveryFee 
                          --,SF.ServiceFeeFactorValue AS DeliveryFee   
					FROM dbo.InvoiceDetails ID With(NOLOCK)
					INNER JOIN InvoicesSupplier ISup With(NOLOCK) ON ID.SupplierInvoiceID = ISup.SupplierInvoiceID
					--INNER JOIN dbo.ServiceFees  SF With(NOLOCK) ON SF.SupplierID=ID.SupplierID --AND SF.StoreID=ID.StoreID AND SF.ProductID=ID.ProductID
					inner join chains c on c.ChainID = id.ChainID 

					WHERE ISup.SupplierInvoiceID='''+@InvoiceNo+''' and C.ChainIdentifier = '''+ @ChainID + ''''
       
SET @SqlReturnsNew= 'SELECT Distinct legacySystemStoreIdentifier AS StoreId,InvoiceNo AS CreditesOnInvoice,supplieridentifier AS WholesalerID,TitleName,
					  
					  (mondaydraw-mondayPOS) AS MonR,
					  (tuesdaydraw-tuesdayPOS) AS TueR,
					  (wednesdaydraw-wednesdayPOS) AS WedR,
					  (thursdaydraw-thursdayPOS) AS ThurR,
					  (fridaydraw-fridayPOS) AS FriR,
					  (saturdaydraw-saturdayPOS) AS SatR,
					  (sundaydraw-sundayPOS) AS  SunR ,
					  
					 --    case when mondaydraw = ''0'' then   mondayPOS else (mondaydraw-mondayPOS) end  AS MonR,
						--case when tuesdaydraw = ''0'' then   tuesdayPOS else (tuesdaydraw-tuesdayPOS) end  AS TueR,
						--case when wednesdaydraw = ''0'' then   wednesdayPOS else (wednesdaydraw-wednesdayPOS) end  AS WedR,
						--case when thursdaydraw = ''0'' then   thursdayPOS else (thursdaydraw-thursdayPOS) end  AS ThurR,
						--case when fridaydraw = ''0'' then   fridayPOS else (fridaydraw-fridayPOS) end  AS FriR,
						--case when saturdaydraw = ''0'' then   saturdayPOS else (saturdaydraw-saturdayPOS) end  AS SatR,
						--case when sundaydraw = ''0'' then   sundayPOS else (sundaydraw-sundayPOS) end  AS SunR,
						
					     0 AS MonPh,0 AS TuePh,0 AS WedPh,0 AS ThurPh,0 AS FriPh,0 AS SatPh,0 AS SunPh,0 AS PhysicalCount,costtostore,SuggRetail
					  	
					  FROM  ##tempFinalData ' 	
      
		 
		 /*----EXEC DRAWS QUERY------*/      
		SET @SqlFinal=@sqlDrawsOld + ' UNION ' + @SqlDrawsNew + ' ORDER BY TitleName '
		EXEC(@SqlFinal)
		PRINT(@SqlFinal)
		 
		/*----EXEC INVOICE QUERY------*/  
		SET @SqlFinal=@sqlInvoiceOld + ' UNION ' + @sqlInvoiceNew 
		EXEC(@SqlFinal)
		
		/*----EXEC RETURNS QUERY------*/  
		SET @SqlFinal=@sqlReturnsOld + ' UNION ' + @SqlReturnsNew + ' ORDER BY TitleName ' 
		EXEC(@SqlFinal) 
		PRINT(@SqlFinal)
	
	
	IF object_id('tempdb.dbo.##tempDraws') is not null 
	BEGIN
	  drop table ##tempDraws;
	END
	
	IF object_id('tempdb.dbo.##tempPOS') is not null
		BEGIN
		   drop table ##tempPOS
		END	
		
		
	IF object_id('tempdb.dbo.##tempFinalData') is not null
		BEGIN
		   drop table ##tempFinalData
		END	
	
END
GO
