USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_DrawRegulationCHN_GetStoreTotal]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec amb_DrawRegulationCHN_GetStoreTotal 'DQ','62362','-1','MS','','08/18/2013','09/06/2013'
--Exec amb_DrawRegulationCHN_GetStoreTotal 'BN','42493','FL','LAKEWALES','Financial','1900/01/01','1900/01/01'
CREATE procedure [dbo].[amb_DrawRegulationCHN_GetStoreTotal]
(
@ChainIdentifier varchar(10),
@ChainID varchar(10),
@State varchar(40),
@City varchar(50),
@StoreNumber varchar(50),
@StartDate varchar(20),
@EndDate varchar(20)
)

as 
BEGIN

Declare @sqlQueryNew varchar(8000)
declare @strquery varchar(8000)

		if object_id('tempdb.dbo.##tempDrawRegulationDrawsCHN') is not null
			begin
				drop table ##tempDrawRegulationDrawsCHN;
			end

		set @strquery=' select st.ChainID,st.SupplierID,st.ProductID,st.storeid,Qty,TransactionTypeID,
										datename(W,SaleDateTime)+ ''Draw'' as "wDay"
										into ##tempDrawRegulationDrawsCHN

										from DataTrue_Report.dbo.Storetransactions_forward st
										INNER JOIN DataTrue_Report.dbo.Stores s ON s.StoreID=st.StoreID
										INNER JOIN DataTrue_Report.dbo.Addresses a ON a.OwnerEntityID=st.StoreID 

										where TransactionTypeID in (29)
										and st.chainid='''+@ChainID+'''
										and s.LegacySystemStoreIdentifier like ''%'+@StoreNumber+'%'''
		if(@City<>'-1')   
			set @strquery = @strquery +' and a.City like '''+@City+''''							   

		if(@State<>'-1')    
			set @strquery = @strquery +' and	a.State like '''+@State+''''

		if(cast(@StartDate as date) > cast('1900-01-01' as date))
			set @strquery = @strquery +' and (SELECT TOP 1 dateadd(dd, BillingControlDay - (datepart (dw, (ST.SaleDateTime))), ST.SaleDateTime)
      FROM
      BillingControl BC
      WHERE
      BC.ChainID = st.ChainID
      AND BC.EntityIDToInvoice = st.SupplierID) >= ''' + convert(varchar, +@StartDate,101) +  ''''
		if(cast( @EndDate as date ) >cast('1900-01-01' as date)) 
			set @strquery = @strquery +' AND (SELECT TOP 1 dateadd(dd, BillingControlDay - (datepart (dw, (ST.SaleDateTime))), ST.SaleDateTime)
      FROM
      BillingControl BC
      WHERE
      BC.ChainID = st.ChainID
      AND BC.EntityIDToInvoice = st.SupplierID) <= ''' + convert(varchar, +@EndDate,101) + ''''
			print @strquery
		EXEC(@strquery)
		--Get the data into tmp table for POS	

		if object_id('tempdb.dbo.##tempDrawRegulationPOSCHN') is not null
			begin
				drop table ##tempDrawRegulationPOSCHN;
			end
		set @strquery='select distinct st.ChainID,st.SupplierID,st.storeid,st.ProductID,Qty,st.TransactionTypeID,
									datename(W,SaleDateTime)+ ''POS'' as "POSDay"

									into ##tempDrawRegulationPOSCHN

									from DataTrue_Report.dbo.Storetransactions st
									inner join DataTrue_Report.dbo.transactiontypes tt on tt.transactiontypeid=st.transactiontypeid and tt.buckettype=1
									INNER JOIN DataTrue_Report.dbo.Stores s ON s.StoreID=st.StoreID
									INNER JOIN DataTrue_Report.dbo.Addresses a ON a.OwnerEntityID=st.StoreID 

									where st.chainid='''+@ChainID+'''
									and s.LegacySystemStoreIdentifier like ''%'+@StoreNumber+'%'''
		if(@City<>'-1')   
			set @strquery = @strquery +' and a.City like '''+@City+''''							   

		if(@State<>'-1')    
			set @strquery = @strquery +' and	a.State like '''+@State+''''

		if(cast(@StartDate as date ) > cast('1900-01-01' as date))
			set @strquery = @strquery +' and (SELECT TOP 1 dateadd(dd, BillingControlDay - (datepart (dw, (ST.SaleDateTime))), ST.SaleDateTime)
      FROM
      BillingControl BC
      WHERE
      BC.ChainID = st.ChainID
      AND BC.EntityIDToInvoice = st.SupplierID) >= ''' + convert(varchar, +@StartDate,101) +  ''''
		if(cast(@EndDate as date ) > cast('1900-01-01' as date)) 
			set @strquery = @strquery +' AND (SELECT TOP 1 dateadd(dd, BillingControlDay - (datepart (dw, (ST.SaleDateTime))), ST.SaleDateTime)
      FROM
      BillingControl BC
      WHERE
      BC.ChainID = st.ChainID
      AND BC.EntityIDToInvoice = st.SupplierID) <= ''' + convert(varchar, +@EndDate,101) + ''''
		
		EXEC(@strquery)

		--Get the final data into final tmp table

		if object_id('tempdb.dbo.##tempDrawRegulationCHNFinalData') is not null
			begin
				drop table ##tempDrawRegulationCHNFinalData
			end

		set @strquery='Select distinct tmpdraws.*,
									tmpPOS.MondayPOS,tmpPOS.TuesdayPOS,tmpPOS.WednesdayPOS,tmpPOS.ThursdayPOS,
									tmpPOS.FridayPOS,tmpPOS.SaturdayPOS,tmpPOS.SundayPOS,
									CAST(NULL as nvarchar(50)) as "BiPad",
									CAST(NULL as nvarchar(225)) as "Title"

									into ##tempDrawRegulationCHNFinalData 

									from
									(select * FROM 
									(SELECT * from ##tempDrawRegulationDrawsCHN ) p
									pivot( sum(Qty) for  wDay in (MondayDraw,TuesdayDraw,WednesdayDraw,ThursdayDraw,FridayDraw,SaturdayDraw,SundayDraw)) 
									as Draw_eachday
									) tmpdraws
									join
									( select * from 
									(SELECT * from ##tempDrawRegulationPOSCHN)p
									pivot( sum(Qty) for  POSDay in ( MondayPOS,TuesdayPOS,WednesdayPOS,ThursdayPOS,FridayPOS,SaturdayPOS,SundayPOS)
									) as p1
									) tmpPOS 

									on tmpdraws.chainid=tmpPOS.chainid
									and tmpdraws.supplierid=tmpPOS.supplierid
									and tmpdraws.storeid=tmpPOS.storeid
									and tmpdraws.productid=tmpPOS.productid'
		
		exec(@strquery)


		--Update the required fields
		set @strquery='update f set 
		f.Bipad=(SELECT DISTINCT Bipad from dbo.productidentifiers where ProductID=f.productid),
		f.title=(SELECT DISTINCT  ProductName  from dbo.Products where ProductID=f.productid)
		from ##tempDrawRegulationCHNFinalData f'
		
		exec(@strquery)

		set @sqlQueryNew=' select 
											count(StoreID) AS CountOfStoreID, 
											title as TitleName,
											sum( mondaydraw )AS SumOfMon,
											sum(tuesdaydraw) AS SumOfTue,
											sum(wednesdaydraw) AS SumOfWed, 
											sum(thursdaydraw) AS SumOfThur, 
											sum(fridaydraw) AS SumOfFri, 
											sum(saturdaydraw) AS SumOfSat, 
											sum(sundaydraw) AS SumOfSun, 
											sum(mondaydraw-mondayPOS) AS SumOfMonR, 
											sum(tuesdaydraw-tuesdayPOS) AS SumOfTueR, 
											sum(wednesdaydraw-wednesdayPOS) AS SumOfWedR,
											sum(thursdaydraw-thursdayPOS) AS SumOfThurR, 
											sum(fridaydraw-fridayPOS) AS SumOfFriR, 
											sum(saturdaydraw-saturdayPOS) AS SumOfSatR, 
											sum(sundaydraw-sundayPOS) AS SumOfSunR,
											Sum(mondaydraw+tuesdaydraw+wednesdaydraw+thursdaydraw+fridaydraw+saturdaydraw+sundaydraw) AS TotalDraws, 
											Sum(mondaydraw+tuesdaydraw+wednesdaydraw+thursdaydraw+fridaydraw+saturdaydraw+sundaydraw-
											(mondayPOS+tuesdayPOS+wednesdayPOS+thursdayPOS+fridayPOS+saturdayPOS+sundayPOS)) AS TotalReturns, 
											Sum(mondayPOS+tuesdayPOS+wednesdayPOS+thursdayPOS+fridayPOS+saturdayPOS+sundayPOS) AS TotalNetSales 
											from ##tempDrawRegulationCHNFinalData
											group by title'
			EXEC(@sqlQueryNew)
end
GO
