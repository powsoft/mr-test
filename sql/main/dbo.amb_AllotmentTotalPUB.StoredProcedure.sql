USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_AllotmentTotalPUB]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- select * from dbo.Manufacturers where Manufactureridentifier='DEFAULT'
-- select * from iControl.dbo.Wholesalerslist where wholesalerid='WR688'

-- (Mix) EXEC [amb_AllotmentTotalPUB] 'DEFAULT','0','-1','1900-01-01','-1'
-- (Old) EXEC [amb_AllotmentTotalPUB] 'dowj','35302','WR688','05/06/2007','CVS' 

CREATE procedure [dbo].[amb_AllotmentTotalPUB]
(
	@PublisherIdentifier varchar(50),
	@PublisherId varchar(50),	
	@WholesalerID varchar(10),
	@WeekEnd varchar(50),
	@ChainId varchar(20)
)

AS 
BEGIN

Declare @strqueryNew varchar(8000)
Declare @strqueryNewFinal varchar(8000)


		IF object_id('tempdb.dbo.##tempAllotment') is not null
			BEGIN
				Drop Table ##tempAllotment;
			END
		
		SET @strqueryNew= 'SELECT distinct M.ManufacturerIdentifier AS PublisherID,S.SupplierIdentifier AS WholesalerID,C.ChainIdentifier,
							PID.Bipad,P.ProductName AS TitleName,Qty,datename(W,SaleDateTime)+ ''Allotment'' AS wAllotment,
							ST.SupplierID,ST.ChainID,ST.StoreID,ST.ProductID

							INTO ##tempAllotment
							From DataTrue_Report.dbo.Storetransactions_forward ST
							INNER JOIN  DataTrue_Report.dbo.Brands B ON B.BrandID=st.BrandID
							INNER JOIN  DataTrue_Report.dbo.Manufacturers M ON M.ManufacturerID=B.ManufacturerID
							INNER JOIN  DataTrue_Report.dbo.Suppliers S ON S.SupplierID=ST.SupplierID
							INNER JOIN  DataTrue_Report.dbo.Chains C ON ST.ChainID=c.ChainID
							INNER JOIN  DataTrue_Report.dbo.Products P ON P.ProductID=ST.ProductID
							INNER JOIN  DataTrue_Report.dbo.ProductIdentifiers PID ON PID.ProductID=P.ProductID And ProductIdentifierTypeID=8
							Where TransactionTypeID in (29) AND M.ManufacturerID='+@PublisherId
		
		IF(@WholesalerID<>'-1')					
			SET @strqueryNew += ' and S.SupplierIdentifier='''+@WholesalerID+''''

		IF(@ChainID<>'-1')					
			SET @strqueryNew += ' and C.ChainIdentifier='''+@ChainID+''''
								
		IF(CAST(@WeekEnd as DATE) <> CAST('1900-01-01' as DATE))
				SET @strqueryNew += ' and (SELECT TOP 1 dateadd(dd, BillingControlDay - (datepart (dw, (ST.SaleDateTime))), ST.			SaleDateTime)
				FROM
				BillingControl BC
				WHERE
				BC.ChainID = st.ChainID
      AND BC.EntityIDToInvoice = st.SupplierID) = ''' + convert(varchar, +@WeekEnd,101) +  ''''

		

		EXEC(@strqueryNew)
				
				
		IF object_id('tempdb.dbo.##tempAllotmentsFinalData') is not null
			BEGIN
				Drop Table ##tempAllotmentsFinalData	
			END						
												
		SET @strqueryNew=' Select distinct tempAllotmentsFinal.*,
							CAST(NULL as nvarchar(50)) AS WeekEnding
		  
							INTO ##tempAllotmentsFinalData 
							FROM
							(select * FROM 
								(SELECT * from ##tempAllotment ) p
								 pivot( sum(Qty) For  wAllotment IN
								  (MondayAllotment,TuesdayAllotment,WednesdayAllotment,ThursdayAllotment,
								  FridayAllotment,SaturdayAllotment,SundayAllotment)) as Allotment_EachDay
							) tempAllotmentsFinal '
					
			
		EXEC(@strqueryNew)
					
			
			/* ...........UPDATE THE FIELDS IF REQUIRED..........*/
		SET @strqueryNew='UPDATE F SET 
		
							F.WeekEnding=(select distinct top 1 Saledatetime from dbo.Storetransactions_forward 
							where supplierid=F.supplierid and ChainId=f.ChainId and StoreID=F.StoreID and 
							ProductId=F.ProductId and TransactionTypeID in (29))
							
							FROM ##tempAllotmentsFinalData F'
					
		 EXEC(@strqueryNew)
							
	        
			/*......GET THE FINAL DATA FROM THE NEW DATABASE...........*/
		SET @strqueryNewFinal = 'Select Distinct PublisherID,WholesalerID,ChainIdentifier AS ChainId,Bipad,TitleName,Sum(MondayAllotment) AS MonAllotment,
								Sum(TuesdayAllotment) AS TueAllotment,Sum(WednesdayAllotment) AS WedAllotment,
								Sum(ThursdayAllotment) AS ThurAllotment,Sum(FridayAllotment) AS FriAllotment,
								Sum(SaturdayAllotment) AS SatAllotment,Sum(SundayAllotment) AS SunAllotment,
								Convert(Varchar,Convert(datetime,WeekEnding),101) as WeekEnding
		                        
		                        From ##tempAllotmentsFinalData 
		                        
		                        GROUP BY PublisherID,WholesalerID,ChainIdentifier,Bipad,TitleName,WeekEnding '

	
			EXEC(@strqueryNewFinal + ' order by TitleName ')
			
END
GO
