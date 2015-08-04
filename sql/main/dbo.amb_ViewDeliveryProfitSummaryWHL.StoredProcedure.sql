USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_ViewDeliveryProfitSummaryWHL]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec [amb_ViewDeliveryProfitSummaryWHL] '-1','-1','-1','','2012-04-15','ENT','24178'
--exec [amb_ViewDeliveryProfitSummaryWHL] 'BN','-1','-1','','04/15/2012','WR1428','24503'
--exec [amb_ViewDeliveryProfitSummaryWHL] 'CVS','-1','-1','','04/15/2011','WR1428','24503'

--exec [amb_ViewDeliveryProfitSummaryWHL] 'DQ','-1','-1','','08/18/2013','CLL','24164'


CREATE procedure [dbo].[amb_ViewDeliveryProfitSummaryWHL]
(
	@ChainID varchar(10),
	@State varchar(10),
	@City varchar(30),
	@StoreNumber varchar(10),
	@Weekend varchar(25),
	@SupplierIdentifier varchar(10),
	@SupplierID varchar(10)
)

AS
BEGIN

	
	Declare @sqlQueryNew varchar(8000)

			--Get the data in to tmp table for draws
			
				if object_id('tempdb.dbo.##tempViewDeliveryProfitSummaryDraws') is not null
					begin
						drop table ##tempViewDeliveryProfitSummaryDraws;
					end
				declare @strquery varchar(8000)
				set @strquery='select distinct st.ChainID,st.SupplierID,s.storeid,
							st.ProductID,Qty,TransactionTypeID,
							datename(W,SaleDateTime)+ ''Draw'' as "wDay"
							into ##tempViewDeliveryProfitSummaryDraws
							from DataTrue_Report.dbo.Storetransactions_forward st
							inner JOIN DataTrue_Report.dbo.Chains c on st.ChainID=c.ChainID
							INNER JOIN DataTrue_Report.dbo.Stores s ON s.StoreID=st.StoreID
							INNER JOIN DataTrue_Report.dbo.Addresses a ON a.OwnerEntityID=st.StoreID 
							where TransactionTypeID in (29) 
							and s.LegacySystemStoreIdentifier like ''%'+@StoreNumber+'%'' 
							and st.supplierid=' + @SupplierID 
			
			if(@ChainID<>'-1')					
				set @strquery = @strquery +' and c.ChainIdentifier='''+@ChainID+''''
			
			if(@City<>'-1')   
				set @strquery = @strquery +' and a.City like '''+@City+''''	
			
			if(@State<>'-1')    
				set @strquery = @strquery +' and	a.State like '''+@State+''''
									
			if(CAST(@Weekend AS DATE) <> CAST('1900-01-01' AS DATE))
				set @strquery = @strquery +' and (SELECT TOP 1 dateadd(dd, BillingControlDay - (datepart (dw, (ST.SaleDateTime))), ST.SaleDateTime)
						FROM
						BillingControl BC
						WHERE
						BC.ChainID = st.ChainID
						AND BC.EntityIDToInvoice = st.SupplierID)   = ''' + convert(varchar, +@Weekend,101) +  ''''
		
		
					
			EXEC(@strquery)	
			
			--Get the data into tmp table for POS
			
			if object_id('tempdb.dbo.##tempViewDeliveryProfitSummaryPOS') is not null
				begin
				drop table ##tempViewDeliveryProfitSummaryPOS
				end	
				
			set @strquery='select distinct st.ChainID,st.SupplierID,
							s.storeid,
							st.ProductID,Qty,st.TransactionTypeID,
							datename(W,SaleDateTime)+ ''POS'' as "POSDay"						
							into ##tempViewDeliveryProfitSummaryPOS						
							
							from DataTrue_Report.dbo.Storetransactions st
							inner join DataTrue_Report.dbo.transactiontypes tt on tt.transactiontypeid=st.transactiontypeid 
							and tt.buckettype=1
							inner JOIN DataTrue_Report.dbo.Chains c on st.ChainID=c.ChainID
							INNER JOIN DataTrue_Report.dbo.Stores s ON s.StoreID=st.StoreID
							INNER JOIN DataTrue_Report.dbo.Addresses a ON a.OwnerEntityID=st.StoreID 										
							
							where 1=1
							and st.supplierid=' + @SupplierID + '
							and s.LegacySystemStoreIdentifier like ''%'+@StoreNumber+'%'''
			
			if(@ChainID<>'-1')					
				set @strquery = @strquery +' and c.ChainIdentifier='''+@ChainID+''''							
			
			if(@City<>'-1')   
				set @strquery = @strquery +' and a.City like '''+@City+''''							   

			if(@State<>'-1')    
				set @strquery = @strquery +' and	a.State like '''+@State+''''
										
			if(CAST(@Weekend as DATE) <> CAST('1900-01-01' as DATE))
				set @strquery = @strquery +' and (SELECT TOP 1 dateadd(dd, BillingControlDay - (datepart (dw, (ST.SaleDateTime))), ST.SaleDateTime)
						FROM
						BillingControl BC
						WHERE
						BC.ChainID = st.ChainID
						AND BC.EntityIDToInvoice = st.SupplierID)   = ''' +  convert(varchar, +@Weekend,101) +  ''''
		
			
			EXEC(@strquery)	
			
			
			if object_id('tempdb.dbo.##tempViewDeliveryProfitSummaryFinalData') is not null
				begin
				drop table ##tempViewDeliveryProfitSummaryFinalData	
			end						
		  
		  set @strquery='Select distinct tmpdraws.*,
							tmpPOS.MondayPOS,tmpPOS.TuesdayPOS,tmpPOS.
							WednesdayPOS,tmpPOS.ThursdayPOS,
							tmpPOS.FridayPOS,tmpPOS.SaturdayPOS,tmpPOS.SundayPOS,
							CAST(NULL as nvarchar(50)) as "WholesalerName",		
							CAST(NULL as nvarchar(50)) as "LegacySystemStoreIdentifier",				
							CAST(NULL as nvarchar(50)) as "StoreNumber",
							CAST(NULL as nvarchar(50)) as "StoreName",
							CAST(NULL as nvarchar(100)) as "Address",
							CAST(NULL as nvarchar(50)) as "City",
							CAST(NULL as nvarchar(50)) as "State",
							CAST(NULL as nvarchar(50)) as "ZipCode",
							CAST(NULL as nvarchar(225)) as "Title",
							CAST(NULL as MONEY) as "CostToStore",
							CAST(NULL as MONEY) as "SuggRetail",
							CAST(NULL as nvarchar(50)) as "BiPad",
							CAST(NULL as nvarchar(50)) as "supplieridentifier"
							into ##tempViewDeliveryProfitSummaryFinalData 
						from
						(select * FROM 
							(SELECT * from ##tempViewDeliveryProfitSummaryDraws ) p
							 pivot( sum(Qty) for  wDay in
							  (MondayDraw,TuesdayDraw,WednesdayDraw,ThursdayDraw,
							  FridayDraw,SaturdayDraw,SundayDraw)) as Draw_eachday
						) tmpdraws
						join
						( select * from 
							(SELECT * from ##tempViewDeliveryProfitSummaryPOS)p
							 pivot( sum(Qty) for  POSDay in ( MondayPOS,TuesdayPOS,
							 WednesdayPOS,ThursdayPOS,FridayPOS,SaturdayPOS,SundayPOS)
							) as p1
						) tmpPOS 
						on tmpdraws.chainid=tmpPOS.chainid
						and tmpdraws.supplierid=tmpPOS.supplierid
						and tmpdraws.storeid=tmpPOS.storeid
						and tmpdraws.productid=tmpPOS.productid'
			exec(@strquery)
			
				--Update the required fields
			set @strquery='update f set 
				f.WholesalerName=(SELECT DISTINCT SupplierName from dbo.Suppliers
				where SupplierID=f.supplierid),
				f.LegacySystemStoreIdentifier=(select distinct LegacySystemStoreIdentifier from dbo.Stores 
				where StoreID=f.StoreID),
				f.StoreNumber=(select distinct StoreIdentifier from dbo.Stores 
				where StoreID=f.StoreID),				
				f.StoreName=(select distinct StoreName from dbo.Stores  
				where StoreID=f.StoreID),
				f.address=(select distinct Address1 from dbo.Addresses 
				where OwnerEntityID=f.StoreID),
				f.city=(select distinct city from dbo.Addresses where OwnerEntityID=f.StoreID),
				f.state=(select distinct state from dbo.Addresses where OwnerEntityID=f.StoreID),
				f.zipcode=(select distinct PostalCode from dbo.Addresses
				where OwnerEntityID=f.StoreID),
				
				f.costtostore=(SELECT DISTINCT  UnitPrice  from dbo.ProductPrices 
				where ProductID=f.productid AND ChainID=f.chainid and StoreID=f.storeid
				AND SupplierID=f.supplierid and ProductPriceTypeID=3),
				f.SuggRetail=(SELECT DISTINCT  UnitRetail  from dbo.ProductPrices 
				where ProductID=f.productid AND ChainID=f.chainid and StoreID=f.storeid 
				AND SupplierID=f.supplierid and ProductPriceTypeID=3)
			
				from ##tempViewDeliveryProfitSummaryFinalData f'
				exec(@strquery)
				
				
				--Return the Data	
				set @sqlQueryNew='select distinct WholeSalerName,							
								LegacySystemStoreIdentifier as storeid,
								StoreNumber,
								storename,
								address+'' ''+City+'' ''+State+'' ''+zipcode as Address,
								Sum(ISNULL(mondaydraw,0)+ISNULL(tuesdaydraw,0)+ISNULL(wednesdaydraw,0)+ISNULL(thursdaydraw,0)+ISNULL(fridaydraw,0)+ISNULL(saturdaydraw,0)+ISNULL(sundaydraw,0)) AS [Draws],
								Sum(ISNULL(mondaydraw,0)+ISNULL(tuesdaydraw,0)+ISNULL(wednesdaydraw,0)+ISNULL(thursdaydraw,0)+ISNULL(fridaydraw,0)+ISNULL(saturdaydraw,0)+ISNULL(sundaydraw,0)-(ISNULL(mondayPOS,0)+ISNULL(tuesdayPOS,0)+ISNULL(wednesdayPOS,0)+ISNULL(thursdayPOS,0)+ISNULL(fridayPOS,0)+ISNULL(saturdayPOS,0)+ISNULL(sundayPOS,0))) AS [Returns],
								0 AS [Shortages],
								Sum(ISNULL(mondayPOS,0)+ISNULL(tuesdayPOS,0)+ISNULL(wednesdayPOS,0)+ISNULL(thursdayPOS,0)+ISNULL(fridayPOS,0)+ISNULL(saturdayPOS,0)+ISNULL(sundayPOS,0)) AS NetSales, 
								Sum((ISNULL(mondayPOS,0)+ISNULL(tuesdayPOS,0)+ISNULL(wednesdayPOS,0)+ISNULL(thursdayPOS,0)+ISNULL(fridayPOS,0)+ISNULL(saturdayPOS,0)+ISNULL(sundayPOS,0))*(ISNULL(suggretail,0)-ISNULL(CostToStore,0))) AS Profit,
								CASE
									WHEN SUM(ISNULL(mondayPOS,0)+ISNULL(tuesdayPOS,0)+ISNULL(wednesdayPOS,0)+ISNULL(thursdayPOS,0)+ISNULL(fridayPOS,0)+ISNULL(saturdayPOS,0)+ISNULL(sundayPOS,0))>0
									THEN
										CASE
											WHEN SUM(ISNULL(mondaydraw,0)+ISNULL(tuesdaydraw,0)+ISNULL(wednesdaydraw,0)+ISNULL(thursdaydraw,0)+ISNULL(fridaydraw,0)+ISNULL(saturdaydraw,0)+ISNULL(sundaydraw,0)) >0
											  THEN 
													CAST(CAST(SUM(ISNULL(mondayPOS,0)+ISNULL(tuesdayPOS,0)+ISNULL(wednesdayPOS,0)+ISNULL(thursdayPOS,0)+ISNULL(fridayPOS,0)+ISNULL(saturdayPOS,0)+ISNULL(sundayPOS,0)) as Decimal)
													/CAST(SUM(ISNULL(mondaydraw,0)+ISNULL(tuesdaydraw,0)+ISNULL(wednesdaydraw,0)+ISNULL(thursdaydraw,0)+ISNULL(fridaydraw,0)+ISNULL(saturdaydraw,0)+ISNULL(sundaydraw,0))as Decimal)as decimal (18,4))
												ELSE cast(0  as decimal (18,4))
											END
									ELSE cast(0  as decimal (18,4))
								END AS salesRatio
								
								from ##tempViewDeliveryProfitSummaryFinalData
								group by 
									wholesalername,
									LegacySystemStoreIdentifier,
									storename,
									StoreNumber,
									address,
									City,
									State,
									zipcode,
									costtostore,
									suggretail;'
		print(@sqlQueryNew)
			EXEC(@sqlQueryNew)
	
END
GO
