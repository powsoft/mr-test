USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_invoice_whls_pdf_PRESYNC_20150329]    Script Date: 06/25/2015 18:26:30 ******/
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


CREATE PROCEDURE [dbo].[amb_invoice_whls_pdf_PRESYNC_20150329]
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
			SET  @sqlDrawsOld='SELECT Distinct I.InvoiceNo, OnR.WholesalerID,Convert(varchar(12),I.WeekEnding,101) as WeekEnding, 
							P.TitleName as TitleName, OnR.Mon, OnR.Tue, OnR.Wed, OnR.Thur, OnR.Fri, OnR.Sat, OnR.Sun, OnR.MonS, OnR.TueS, OnR.WedS, OnR.								ThurS, OnR.FriS,OnR.SatS, OnR.SunS, OnR.CostToStore, OnR.SuggRetail, OnR.CostToStore4Wholesaler, OnR.CostToWholesaler, SL.StoreName,SL.ChainID,SL.Address,SL.City,SL.State,SL.ZipCode,SL.StoreNumber,SL.StoreID	
											
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
		print @sqlDrawsOld	
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
SET	@SqlTemp = ' Select distinct ST.ChainID,ST.StoreId,ST.SupplierID,Convert(varchar(12),ST.SaleDateTime,101) AS WeekEnding,ID.SupplierInvoiceID AS InvoiceNo,
		  		 P.ProductName AS TitleName,P.ProductId,Qty,TransactionTypeID,datename(W,SaleDateTime)+ ''Draw'' AS [wDay]

				INTO ##tempDraws

				FROM dbo.InvoiceDetails ID
				INNER JOIN dbo.Storetransactions_Forward ST ON ID.SupplierID=ST.SupplierID AND ID.ChainID=ST.ChainID 
				AND ID.StoreID=ST.StoreID AND ID.ProductID=ST.ProductID AND ID.SaleDate=ST.SaleDateTime
				INNER JOIN dbo.Chains C on ST.ChainID=C.ChainID 
				INNER JOIN dbo.Products P ON ST.ProductID = P.ProductID
				INNER JOIN  dbo.Addresses A ON A.OwnerEntityID=ST.StoreID 
				
				
				Where TransactionTypeID in (29)  and ST.SupplierId=' + @SupplierID + ' and ID.SupplierInvoiceID = '''+@InvoiceNo+''' and  C.ChainIdentifier = ''' +@ChainID+''''	
						
EXEC(@SqlTemp)			
                   
IF object_id('tempdb.dbo.##tempPOS') is not null
		BEGIN
		   drop table ##tempPOS
		END	
		
SET	@SqlTemp = 'Select distinct ST.ChainID,ST.StoreId,ST.SupplierID,Convert(varchar(12),ST.SaleDateTime,101) AS WeekEnding,ID.SupplierInvoiceID AS InvoiceNo,
				P.ProductName AS TitleName,P.ProductId,Qty,st.TransactionTypeID,datename(W,SaleDateTime)+ ''POS'' as [POSDay]	
								
				INTO ##tempPOS								

				FROM dbo.InvoiceDetails ID 
				INNER JOIN dbo.Storetransactions ST ON ID.SupplierID=ST.SupplierID AND ID.ChainID=ST.ChainID 
				AND ID.StoreID=ST.StoreID AND ID.ProductID=ST.ProductID AND ID.SaleDate=ST.SaleDateTime
				INNER JOIN dbo.TransactionTypes TT on TT.TransactionTypeID=ST.TransactionTypeID AND TT.BucketType=1 
				INNER JOIN dbo.Chains C on ST.ChainID=C.ChainID
				INNER JOIN dbo.Products P ON	ST.ProductID = P.ProductID
				INNER JOIN  dbo.Addresses A ON A.OwnerEntityID=ST.StoreID 
					 										
				WHERE 1 = 1 AND ST.SupplierId='+@SupplierID + ' and ID.SupplierInvoiceID ='''+@InvoiceNo+''' and C.ChainIdentifier ='''+@ChainID+''''
EXEC(@SqlTemp)


IF object_id('tempdb.dbo.##tempFinalData') is not null
		BEGIN
		   drop table ##tempFinalData
		END	
		
SET	@SqlTemp = 'Select distinct tmpdraws.ChainID,tmpdraws.StoreId,tmpdraws.SupplierID,tmpdraws.WeekEnding,tmpdraws.InvoiceNo,
				tmpdraws.TitleName,tmpdraws.productid,
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
				(SELECT * FROM 
					(SELECT * FROM ##tempDraws ) D
					 PIVOT(SUM(Qty) FOR  wDay in
					  (MondayDraw,TuesdayDraw,WednesdayDraw,ThursdayDraw,
					  FridayDraw,SaturdayDraw,SundayDraw)) AS Draw_eachDay
				) tmpdraws
				INNER JOIN
				( select * FROM
					(SELECT * FROM ##tempPOS) P
					 PIVOT( sum(Qty) FOR  POSDay in ( MondayPOS,TuesdayPOS,
					 WednesdayPOS,ThursdayPOS,FridayPOS,SaturdayPOS,SundayPOS)) AS POS_eachDay
				) tmpPOS 
				ON  tmpdraws.chainid=tmpPOS.chainid
				AND tmpdraws.supplierid=tmpPOS.supplierid
				AND tmpdraws.storeid=tmpPOS.storeid
				AND tmpdraws.productid=tmpPOS.productid '
				
EXEC(@SqlTemp)


SET	@SqlTemp = 'UPDATE F SET 

					F.costtostore=(SELECT DISTINCT  UnitPrice  FROM dbo.ProductPrices WHERE ProductID=f.productid 
									AND ChainID=f.chainid and StoreID=f.storeid	AND SupplierID=f.supplierid and ProductPriceTypeID=3), 
									
					F.legacySystemStoreIdentifier=(SELECT DISTINCT legacySystemStoreIdentifier FROM dbo.Stores  WHERE StoreID=f.StoreID),
					
					F.ChainIdentifier=(SELECT DISTINCT ChainIdentifier FROM dbo.Chains  WHERE ChainId=f.ChainId ),
					
					F.supplieridentifier=(SELECT DISTINCT supplieridentifier FROM dbo.suppliers WHERE supplierid=f.supplierid),
					
					F.SuggRetail=(SELECT DISTINCT  UnitRetail  FROM dbo.ProductPrices WHERE ProductID=F.productid 
					              AND ChainID=F.chainid and StoreID=F.storeid),
					              
					F.StoreName=(select distinct StoreName from dbo.Stores  where StoreID=f.StoreID),
					
				    F.StoreNumber=(select distinct StoreIdentifier from dbo.Stores where StoreID=F.StoreID),
				
				    F.address=(select distinct Address1 from dbo.Addresses where OwnerEntityID=F.StoreID),
				    
				    F.city=(select distinct city from dbo.Addresses where OwnerEntityID=F.StoreID),
				    
				    F.state=(select distinct state from dbo.Addresses where OwnerEntityID=F.StoreID),
				    
				    F.zipcode=(select distinct PostalCode from dbo.Addresses where OwnerEntityID=f.StoreID)              				
					
			    FROM ##tempFinalData F '
EXEC(@SqlTemp)


SET @SqlDrawsNew = 'SELECT Distinct InvoiceNo,supplieridentifier AS WholesalerID,WeekEnding,TitleName,
				   mondaydraw AS Mon,tuesdaydraw AS Tue,wednesdaydraw AS Wed,thursdaydraw AS Thur,fridaydraw AS Fri,saturdaydraw AS Sat,sundaydraw AS Sun,
				   0 AS MonS, 0 AS TueS, 0 AS WedS, 0 AS ThurS, 0 AS FriS, 0 AS SatS, 0 AS SunS,costtostore,SuggRetail,0 AS CostToStore4Wholesaler,
				   0 AS CostToWholesaler,StoreName,ChainIdentifier AS ChainID,Address,City,State,ZipCode,StoreNumber,legacySystemStoreIdentifier AS StoreId

				   FROM  ##tempFinalData  '
	
	
SET @sqlInvoiceNew ='SELECT ID.SupplierInvoiceId AS InvoiceNo,SF.ServiceFeeFactorValue AS DeliveryFee   
					FROM dbo.InvoiceDetails ID
					INNER JOIN dbo.ServiceFees  SF ON SF.SupplierID=ID.SupplierID AND SF.StoreID=ID.StoreID AND SF.ProductID=ID.ProductID

					WHERE ID.SupplierInvoiceId='''+@InvoiceNo+''''
       
SET @SqlReturnsNew= 'SELECT Distinct legacySystemStoreIdentifier AS StoreId,InvoiceNo AS CreditesOnInvoice,supplieridentifier AS WholesalerID,TitleName,
					  (mondaydraw-mondayPOS) AS MonR,(tuesdaydraw-tuesdayPOS) AS TueR,(wednesdaydraw-wednesdayPOS) AS WedR,(thursdaydraw-thursdayPOS) AS ThurR,
					  (fridaydraw-fridayPOS) AS FriR,(saturdaydraw-saturdayPOS) AS SatR,(sundaydraw-sundayPOS) AS  SunR ,
					  0 AS MonPh,0 AS TuePh,0 AS WedPh,0 AS ThurPh,0 AS FriPh,0 AS SatPh,0 AS SunPh,0 AS PhysicalCount,costtostore,SuggRetail
					  	
					  FROM  ##tempFinalData ' 	
	       
		 
		 /*----EXEC DRAWS QUERY------*/      
	SET @SqlFinal=@sqlDrawsOld + ' UNION ' + @SqlDrawsNew + ' ORDER BY TitleName '
	EXEC(@SqlFinal)
	PRINT(@SqlFinal)
	  /*----EXEC INVOICE QUERY------*/  
	SET @SqlFinal=@sqlInvoiceOld + ' UNION ' + @sqlInvoiceNew 
	EXEC(@SqlFinal)
	PRINT(@SqlFinal)
	 /*----EXEC RETURNS QUERY------*/  
	SET @SqlFinal=@sqlReturnsOld + ' UNION ' + @SqlReturnsNew + ' ORDER BY TitleName ' 
	EXEC(@SqlFinal) 
	PRINT(@SqlFinal)
END
GO
