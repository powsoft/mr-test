USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_DeliveryActivitySummaryCHN]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--select * from dbo.chains where chainidentifier='BN'
--exec [amb_DeliveryActivitySummaryCHN] 'BN','42493','IA','SIOUX CITY','','1900/01/01'
--EXEC amb_DeliveryActivitySummaryCHN 'BN','42493','FL','%','BN','2012-12-15'
CREATE procedure [dbo].[amb_DeliveryActivitySummaryCHN]
(
	@ChainIdentifier varchar(10),
	@ChainID varchar(10),
	@State varchar(20),
	@City varchar(20),
	@StoreNumber varchar(10),
	@WeekEndDate varchar(20)
)
as 
BEGIN
	declare @sqlQueryFinal varchar(8000)
	Declare @sqlQueryLegacy varchar(8000)
	Declare @sqlQueryNew varchar(8000)
	Declare @oldStartdate varchar(8000)
	Declare @oldenddate varchar(8000)
	Declare @newStartdate varchar(8000)
	Declare @newenddate varchar(8000)
	Declare @dbType int --0 from Old,1 from New, 2 from mixed
	DECLARE @chain_migrated_date date

	SELECT  @chain_migrated_date = cast(datemigrated as VARCHAR)
	FROM    dbo.chains_migration
	WHERE   chainid = @ChainIdentifier;

if(cast(@chain_migrated_date as date) > cast('01/01/1900' as date))
	begin
		if(cast(@WeekEndDate as date) > cast('01/01/1900' as date))
			begin
				DECLARE @BillingControlDay INT
				select @BillingControlDay=BillingControlDay 
				from dbo.BillingControl bc
				inner join dbo.chains c on c.chainid=bc.chainid
				where  c.chainidentifier=@ChainID 

				DECLARE @TodayDayOfWeek INT
				DECLARE @EndDate DateTime=null
				DECLARE @StartDate DateTime=null
				SET @TodayDayOfWeek = datepart(dw, (@WeekEndDate))
				--get the last day of the previous week (last Sunday)
				SET @EndDate = DATEADD(dd, @BillingControlDay -(@TodayDayOfWeek ), @WeekEndDate)
				--get the first day of the previous week (the Monday before last)
				SET @StartDate = DATEADD(dd,@BillingControlDay -((@TodayDayOfWeek)+6), @WeekEndDate)

				if(cast(@WeekEndDate as date) >= cast(@chain_migrated_date as date))
					Begin
						set @dbType=2
						if(cast(@StartDate as date) >= cast(@chain_migrated_date as date))
							set @newStartdate=@StartDate
						else
							set @newStartdate=DATEADD(dd,1,@chain_migrated_date)
						set @newEnddate=@EndDate
					END
				else if(cast(@WeekEndDate as date) < cast(@chain_migrated_date as date))
						set @dbType=0
			END
		Else
			set @dbType=0
	END
Else
	begin
		set @dbType=0
		set @oldStartdate=@StartDate
		set @oldenddate=@EndDate
	end
	
IF (@dbType=0 or  @dbType=2) 
	BEGIN
		set @sqlQueryLegacy= ' SELECT WL.WholesalerName, SL.Storeid,
								(SL.Address+ '', '' +SL.State+ '', '' +SL.ZipCode) as StoreInfo,
								Sum([mon]+[Tue]+[Wed]+[Thur]+[Fri]+[Sat]+[Sun]) AS Draws,
								Sum([monr]+[tueR]+[wedr]+[ThurR]+[Frir]+[SatR]+[SunR]) AS Returns,
								Sum([mons]+[tues]+[weds]+[ThurS]+[fris]+[SatS]+[SunS]) AS Shortages,
								Sum([mon]+[Tue]+[Wed]+[Thur]+[Fri]+[Sat]+[Sun]-([monr]+[tueR]+[wedr]+[ThurR]+[Frir]+[SatR]+[SunR])-
								([mons]+[tues]+[weds]+[ThurS]+[fris]+[SatS]+[SunS]))AS NetSales,
								Sum(([mon]+[Tue]+[Wed]+[Thur]+[Fri]+[Sat]+[Sun]-([monr]+[tueR]+[wedr]+[ThurR]+[Frir]+[SatR]+[SunR])-([mons]+[tues]+[weds]+										[ThurS]+[fris]+[SatS]+[SunS]))*([SuggRetail]-[CostToStore])) AS Profit ,
								CASE 
									WHEN  Sum([mon]+[Tue]+[Wed]+[Thur]+[Fri]+[Sat]+[Sun]-([monr]+[tueR]+[wedr]+[ThurR]+[Frir]+[SatR]+[SunR])-
											([mons]+[tues]+[weds]+[ThurS]+[fris]+[SatS]+[SunS]))>0  
									THEN  
										Case 
											WHEN Sum([mon]+[Tue]+[Wed]+[Thur]+[Fri]+[Sat]+[Sun])>0	
										
											THEN cast(cast(Sum([mon]+[Tue]+[Wed]+[Thur]+[Fri]+[Sat]+[Sun]-([monr]+[tueR]+[wedr]+[ThurR]+[Frir]+[SatR]+[SunR])-
											([mons]+[tues]+[weds]+[ThurS]+[fris]+[SatS]+[SunS])) as decimal) /
													cast(Sum([mon]+[Tue]+[Wed]+[Thur]+[Fri]+[Sat]+[Sun])as decimal)as decimal (18,4))

											else cast(0 as decimal (18,4))
										END
									else  cast(0 as decimal (18,4))
								END  as salesRatio							

								FROM  [IC-HQSQL2].iControl.dbo.OnR OnR  
								INNER JOIN [IC-HQSQL2].iControl.dbo.Products P ON OnR.Bipad = P.Bipad 
								INNER JOIN [IC-HQSQL2].iControl.dbo.StoresList  SL ON OnR.StoreID = SL.StoreID 
								INNER JOIN  [IC-HQSQL2].iControl.dbo.Wholesalerslist  WL ON OnR.WholesalerID = WL.WholesalerID  
								Where OnR.ChainID=''' + @ChainIdentifier + ''' AND SL.StoreID like ''%' + @StoreNumber+'%''' 

		if(cast(@WeekEndDate as date)>cast('1900/01/01' as date))
       set @sqlQueryLegacy= @sqlQueryLegacy+ ' AND OnR.WeekEnding = '''+@WeekEndDate+'''' 
    if(@City<>'-1')
			 set @sqlQueryLegacy= @sqlQueryLegacy+ ' AND SL.City like ''' + @City+''''
			        
		set @sqlQueryLegacy = @sqlQueryLegacy + ' GROUP BY 
										WL.WholesalerName, 
										SL.Storeid, 
										SL.Address,
										SL.State, 
										SL.ZipCode'


		set @sqlQueryLegacy = @sqlQueryLegacy + ' HAVING 1=1 '
		if(@State<>'-1')
			 set @sqlQueryLegacy= @sqlQueryLegacy+ ' AND SL.State like '''+@State+''''
	
		    

	end
IF (@dbType=1 or  @dbType=2) 
	BEGIN
		if object_id('tempdb.dbo.##tempDeliveryActivitySummaryCHN') is not null
			drop table ##tempDeliveryActivitySummaryCHN;
		
		declare @strquery varchar(8000)
		
		set @strquery='select distinct st.ChainID,st.SupplierID,st.storeid,st.ProductID,Qty,
									TransactionTypeID,datename(W,SaleDateTime)+ ''Draw'' as "wDay" 
									into ##tempDeliveryActivitySummaryCHN

									from dbo.Storetransactions_forward st
									INNER JOIN dbo.Stores s ON s.StoreID=st.StoreID
									INNER JOIN dbo.Addresses a ON a.OwnerEntityID=st.StoreID 

									where TransactionTypeID in (29)
									and st.ChainId='''+@ChainID+'''
									and s.LegacySystemStoreIdentifier like ''%'+@StoreNumber+'%'''
		if(@City<>'-1')   
		set @strquery = @strquery +' and a.City like '''+@City+''''							   

		if(@State<>'-1')    
		set @strquery = @strquery +' and	a.State like '''+@State+''''

		if(Cast(@newStartdate as date) > Cast('1900-01-01' as date))
			set @strquery = @strquery +' and SaleDateTime >= ''' + convert(varchar, +@newStartdate,101) +  ''''
		if(cast(@newEnddate as date) > cast('1900-01-01' as date)) 
			set @strquery = @strquery +' AND SaleDateTime <= ''' + convert(varchar, +@newEnddate,101) + ''''

		EXEC(@strquery)

		--Get the data into tmp table for POS	

		if object_id('tempdb.dbo.##tempDeliveryActivityPOSSummaryCHN') is not null
			drop table ##tempDeliveryActivityPOSSummaryCHN;
	
		set @strquery='select distinct st.ChainID,st.SupplierID,st.storeid,st.ProductID,Qty,
									st.TransactionTypeID,datename(W,SaleDateTime)+ ''POS'' as "POSDay"
									into ##tempDeliveryActivityPOSSummaryCHN

									from dbo.Storetransactions st
									inner join dbo.transactiontypes tt on tt.transactiontypeid=st.transactiontypeid and tt.buckettype=1
									INNER JOIN dbo.Stores s ON s.StoreID=st.StoreID
									INNER JOIN dbo.Addresses a ON a.OwnerEntityID=st.StoreID 

									where st.ChainId='''+@ChainID+''' 
									and s.LegacySystemStoreIdentifier like ''%'+@StoreNumber+'%'''

		if(@City<>'-1')   
		set @strquery = @strquery +' and a.City like '''+@City+''''							   

		if(@State<>'-1')    
		set @strquery = @strquery +' and	a.State like '''+@State+''''

		if(Cast( @newStartdate as date ) > Cast('1900-01-01' as Date))
			set @strquery = @strquery +' and SaleDateTime >= ''' + convert(varchar, +@newStartdate,101) +  ''''
		if(Cast( @newEnddate as date) > Cast('1900-01-01' as date)) 
			set @strquery = @strquery +' AND SaleDateTime <= ''' + convert(varchar, +@newEnddate,101) + ''''

		EXEC(@strquery)			

		--Get the final data into final tmp table

		if object_id('tempdb.dbo.##tempDeliveryActivityCHNSummaryFinalData') is not null
			drop table ##tempDeliveryActivityCHNSummaryFinalData

		set @strquery='Select distinct tmpdraws.*,
					tmpPOS.MondayPOS,tmpPOS.TuesdayPOS,tmpPOS.WednesdayPOS,tmpPOS.ThursdayPOS,
					tmpPOS.FridayPOS,tmpPOS.SaturdayPOS,tmpPOS.SundayPOS,
					CAST(NULL as nvarchar(50)) as "LegacySystemStoreIdentifier",
					CAST(NULL as nvarchar(100)) as "Address",
					CAST(NULL as nvarchar(50)) as "State",
					CAST(NULL as nvarchar(50)) as "ZipCode",
					CAST(NULL as nvarchar(50)) as "WholesalerName",
					CAST(NULL as MONEY) as "CostToStore",
					CAST(NULL as money) as "SuggRetail"
					into ##tempDeliveryActivityCHNSummaryFinalData
					from
					(select * FROM 
					(SELECT * from ##tempDeliveryActivitySummaryCHN ) p
					pivot( sum(Qty) for  wDay in (MondayDraw,TuesdayDraw,WednesdayDraw,ThursdayDraw,FridayDraw,SaturdayDraw,SundayDraw)) as Draw_eachday
					) tmpdraws
					join
					( select * from 
					(SELECT * from ##tempDeliveryActivityPOSSummaryCHN)p
					pivot( sum(Qty) for  POSDay in ( MondayPOS,TuesdayPOS,WednesdayPOS,ThursdayPOS,FridayPOS,SaturdayPOS,SundayPOS)
					) as p1
					) tmpPOS 
					on tmpdraws.chainid=tmpPOS.chainid and tmpdraws.supplierid=tmpPOS.supplierid
					and tmpdraws.storeid=tmpPOS.storeid and tmpdraws.productid=tmpPOS.productid'
	
		exec(@strquery)


		--Update the required fields
		set @strquery='update f set 
		f.WholesalerName=(SELECT DISTINCT SupplierName from dbo.Suppliers where SupplierID=f.supplierid),
		f.LegacySystemStoreIdentifier=(select distinct LegacySystemStoreIdentifier from dbo.Stores  where StoreID=f.StoreID),
		f.address=(select distinct Address1 from dbo.Addresses where OwnerEntityID=f.StoreID),
		f.state=(select distinct state from dbo.Addresses where OwnerEntityID=f.StoreID),
		f.zipcode=(select distinct PostalCode from dbo.Addresses where OwnerEntityID=f.StoreID),
	f.costtostore=(SELECT DISTINCT  UnitPrice  from dbo.ProductPrices where ProductID=f.productid AND ChainID=f.chainid 
		and StoreID=f.storeid AND SupplierID=f.supplierid and ProductPriceTypeID=3),
		f.SuggRetail=(SELECT DISTINCT  UnitRetail  from dbo.ProductPrices where ProductID=f.productid AND ChainID=f.chainid 
		and StoreID=f.storeid AND SupplierID=f.supplierid and ProductPriceTypeID=3)	
		
		from ##tempDeliveryActivityCHNSummaryFinalData f'

		exec(@strquery)
		
		set @sqlQueryNew=' select distinct wholesalername,
					LegacySystemStoreIdentifier as StoreID, (Address + '', '' + State + '', ''+ ZipCode) as StoreInfo,
					Sum(mondaydraw+tuesdaydraw+wednesdaydraw+thursdaydraw+fridaydraw+saturdaydraw+sundaydraw) AS Draws,
					Sum(mondaydraw+tuesdaydraw+wednesdaydraw+thursdaydraw+fridaydraw+saturdaydraw+sundaydraw-(mondayPOS+tuesdayPOS+wednesdayPOS+thursdayPOS+fridayPOS+saturdayPOS+sundayPOS)) AS Returns,
					0 AS Shortages,
					SUM(mondayPOS+tuesdayPOS+wednesdayPOS+thursdayPOS+fridayPOS+saturdayPOS+sundayPOS) AS NetSales, 
					Sum(mondayPOS+tuesdayPOS+wednesdayPOS+thursdayPOS+fridayPOS+saturdayPOS+sundayPOS)*(suggretail-CostToStore) AS Profit,
					CASE
							WHEN SUM(mondayPOS+tuesdayPOS+wednesdayPOS+thursdayPOS+fridayPOS+saturdayPOS+sundayPOS)>0
							
							THEN
								CASE
									WHEN SUM(mondaydraw+tuesdaydraw+wednesdaydraw+thursdaydraw+fridaydraw+saturdaydraw+sundaydraw) >0
									  THEN 
										CAST(CAST(SUM(mondayPOS+tuesdayPOS+wednesdayPOS+thursdayPOS+fridayPOS+saturdayPOS+sundayPOS) as Decimal)/CAST(SUM												(mondaydraw+tuesdaydraw+wednesdaydraw+thursdaydraw+fridaydraw+saturdaydraw+sundaydraw)as Decimal)as decimal (18,4))
									ELSE cast(0  as decimal (18,4))
								END
							ELSE cast(0  as decimal (18,4))
						END AS salesRatio	
					from 
					##tempDeliveryActivityCHNSummaryFinalData
					group by chainid,
							wholesalername,
							LegacySystemStoreIdentifier,
							address,
							State,
							zipcode,
							suggretail,
							CostToStore'
	END
	
	
if(@dbType=2)
		EXEC(@sqlQueryLegacy+ ' union ' +@sqlQueryNew+' Order By StoreID,StoreInfo,wholesalername')
else IF(@dbType=1)
		EXEC(@sqlQueryNew+' Order By StoreID,StoreInfo,wholesalername')
else IF(@dbType=0)
		EXEC(@sqlQueryLegacy+' Order By StoreID,StoreInfo,wholesalername')		
		
		
		
		
End
GO
