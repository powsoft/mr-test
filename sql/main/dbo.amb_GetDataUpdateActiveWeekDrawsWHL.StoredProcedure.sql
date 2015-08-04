USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_GetDataUpdateActiveWeekDrawsWHL]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--select * from dbo.suppliers where supplierIdentifier='ENT'
-- exec amb_GetDataUpdateActiveWeekDrawsWHL 'ENT','24178','-1','-1','KNG3900','11/06/2012'
-- exec amb_GetDataUpdateActiveWeekDrawsWHL 'WR1428','24503','-1','-1','','1900-01-01'
--exec amb_GetDataUpdateActiveWeekDrawsWHL 'WR1428','24503','TA','-1','','11/06/2012'
--select * from chains_migration
  
--'11/11/2012'

CREATE procedure [dbo].[amb_GetDataUpdateActiveWeekDrawsWHL]
(
  @SupplierIdentifier varchar(10),
	@SupplierId varchar(20),
	@ChainID varchar(10),
	@State varchar(10),
	@StoreNumber varchar(10),
	@WeekEnd varchar(50) 	
)
as 
BEGIN

	declare @sqlQueryFinal varchar(8000)	
	DECLARE @sqlQueryStoreLegacy VARCHAR(8000)
	DECLARE @sqlQueryStorenewDB VARCHAR(8000)
	DECLARE @sqlQueryLegacy VARCHAR(8000)
	DECLARE @sqlQueryNew VARCHAR(8000)
	

	Declare @BillingControlDay varchar(20)
	Declare @newStartdate varchar(20)='01/01/1900'
	Declare @newenddate varchar(20)='01/01/1900'
	Declare @TodayDayOfWeek int
	Declare @EndOfWeek varchar(20)
	Declare @StartOfWeek varchar(20)
	Declare @DBType int --0 for old database,1 from new database, 2 from mixed
	DECLARE @chain_migrated_date date
	
	if(@ChainID<>'-1')
		BEgin
			SELECT  @chain_migrated_date = cast(datemigrated as VARCHAR) FROM    dbo.chains_migration WHERE   chainid = @ChainID;

			if(CAST(@chain_migrated_date as DATE) > CAST('01/01/1900' as DATE))
				begin
					SELECT @BillingControlDay=BillingControlDay 
					FROM dbo.BillingControl bc 
					INNER JOIN dbo.chains c ON c.chainid=bc.chainid
					WHERE  c.chainidentifier=@ChainID 
					
					SET @TodayDayOfWeek = datepart(dw, @WeekEnd)
					SET @EndOfWeek=DATEADD(dd,(@BillingControlDay -@TodayDayOfWeek), @WeekEnd)
					SET @StartOfWeek=DATEADD(dd, @BillingControlDay-(@TodayDayOfWeek+6), @WeekEnd)

					if(CAST(@Weekend as DATE) >= CAST(@chain_migrated_date as DATE))
						Begin
							set @dbType=2
							if(cast(@StartOfWeek as date) >= cast(@chain_migrated_date as date))
								set @newStartdate=@StartOfWeek
							else
								set @newStartdate=DATEADD(dd,1,@chain_migrated_date)
							set @newenddate=@EndOfWeek
						END
					else if(CAST(@Weekend as DATE) < CAST(@chain_migrated_date as DATE))
						begin
							set @DBType=0
						End
				end
			else
				begin
					set @DBType=0
				end
		END
	ELSE
		Begin
			set @DBType=2
		END
		
print @DBType
IF (@DBType=0 or  @DBType=2)
		Begin
			set @sqlQueryStoreLegacy='SELECT distinct OnR.chainid,SL.StoreNumber, SL.StoreID, SL.StoreName, 
								SL.Address,SL.City, SL.State, SL.ZipCode ,Convert(varchar,OnR.WeekEnding,101) as WeekEnding
								FROM  [IC-HQSQL2].iControl.dbo.Products P
								INNER JOIN ([IC-HQSQL2].iControl.dbo.OnR OnR   INNER JOIN  [IC-HQSQL2].iControl.dbo.StoresList  SL ON OnR.StoreID = SL.StoreID) 
								ON P.Bipad = OnR.Bipad where 1=1 '

		set @sqlQueryStoreLegacy = @sqlQueryStoreLegacy + ' AND OnR.WholesalerID=''' + @SupplierIdentifier + ''''
   
		if(@ChainID<>'-1')
		   set @sqlQueryStoreLegacy= @sqlQueryStoreLegacy+ ' AND OnR.ChainID = '''+@ChainID+''''	
		   
		if(@State<>'-1')    
		   set @sqlQueryStoreLegacy = @sqlQueryStoreLegacy +' and SL.State like '''+@State+''''  
				
		if(@StoreNumber<>'')
		   set @sqlQueryStoreLegacy= @sqlQueryStoreLegacy+ ' AND SL.StoreID like ''%' + @StoreNumber+'%'' '
		     
		 if(CAST(@WeekEnd as DATE) <> CAST('1900-01-01'as DATE))
		   set @sqlQueryStoreLegacy= @sqlQueryStoreLegacy+' AND OnR.WeekEnding= '''+ convert(varchar,+@WeekEnd,101) +''' '
		   
		set @sqlQueryLegacy='Select Distinct (''Store : '' + SL.StoreNumber + '','' + SL.Address + '',	'' + SL.City +
							 '','' + SL.ChainID + '' , Store # : '' + SL.StoreNumber + '' /n	Location : '' + SL.StoreNumber + '', '' + SL.City + '','' + SL.Address + '',	'' + SL.State + '', '' + SL.ZipCode 
							 +'' , Week Ending :''+ Convert(varchar,OnR.WeekEnding,101)) as StoreInfo,
							 OnR.chainid,SL.StoreID,SL.StoreNumber , SL.StoreName, 
								SL.Address,SL.City, SL.State, SL.ZipCode , P.bipad , P.AbbrvName as TitleName,
							OnR.Mon,OnR.Tue,OnR.Wed, OnR.Thur, OnR.Fri, OnR.Sat, OnR.Sun,
							Convert(varchar,OnR.WeekEnding,101) as WeekEnding,0 as dbType
							FROM  [IC-HQSQL2].iControl.dbo.Products P
							INNER JOIN (  [IC-HQSQL2].iControl.dbo.OnR OnR   INNER JOIN  [IC-HQSQL2].iControl.dbo.StoresList  SL ON OnR.StoreID = SL.StoreID) 
							ON P.Bipad = OnR.Bipad where 1=1 '

		set @sqlQueryLegacy = @sqlQueryLegacy + ' AND OnR.WholesalerID=''' + @SupplierIdentifier + ''''
   
		if(@ChainID<>'-1')
		   set @sqlQueryLegacy= @sqlQueryLegacy+ ' AND OnR.ChainID = '''+@ChainID+''''	
		   
		if(@State<>'-1')    
		   set @sqlQueryLegacy = @sqlQueryLegacy +' and SL.State like '''+@State+''''  
				
		if(@StoreNumber<>'')
		   set @sqlQueryLegacy= @sqlQueryLegacy+ ' AND SL.StoreID like ''%' + @StoreNumber+'%'' '
		     
		if(CAST(@WeekEnd as DATE) <> CAST('1900-01-01' as DATE))
		   set @sqlQueryLegacy= @sqlQueryLegacy+' AND OnR.WeekEnding= '''+ Convert(varchar,+@WeekEnd,101) +''' '

End


IF (@DBType=1 or  @DBType=2) 
			BEGIN
			--Get the data in to tmp table for draws
			
				if object_id('tempdb.dbo.##tempDataUpdateActiveDraws') is not null
					begin
						drop table ##tempDataUpdateActiveDraws;
					end
				declare @strquery varchar(8000)
				set @strquery= 'select distinct st.ChainID,st.SupplierID,s.storeid,
								st.ProductID,Qty,TransactionTypeID,
								datename(W,SaleDateTime)+ ''Draw'' as "wDay"
								into ##tempDataUpdateActiveDraws
								from dbo.Storetransactions_forward st
								inner JOIN dbo.Chains c on st.ChainID=c.ChainID
								INNER JOIN dbo.Stores s ON s.StoreID=st.StoreID
								INNER JOIN dbo.Addresses a ON a.OwnerEntityID=st.StoreID 
								where TransactionTypeID in (29) 
								and st.supplierid=' + @SupplierId + ' 
								and s.LegacySystemStoreIdentifier like ''%'+@StoreNumber+'%''' 
	
			if(@ChainID<>'-1')					
				set @strquery = @strquery +' and c.ChainIdentifier='''+@ChainID+''''
			
			if(@State<>'-1')    
				set @strquery = @strquery +' and a.State like '''+@State+''''
									
			if(CAST(@newStartdate as DATE) <> CAST('1900-01-01' as DATE))
				set @strquery = @strquery +' and SaleDateTime >= ''' + convert(varchar, +@newStartdate,101) +  ''''
		
			if(CAST(@newEnddate as DATE ) <> CAST('1900-01-01' as DATE)) 
				set @strquery = @strquery +' AND SaleDateTime <= ''' + convert(varchar, +@newEnddate,101) + ''''
				
			
			EXEC(@strquery)
				
			if object_id('tempdb.dbo.##tempDataUpdateActiveFinalData') is not null
				begin
				drop table ##tempDataUpdateActiveFinalData	
			end						
													
		  set @strquery='Select distinct tmpdraws.*,
						    CAST(NULL as nvarchar(50)) as "StoreNumber",
						    CAST(NULL as nvarchar(50)) as "WeekEnding",
						    CAST(NULL as nvarchar(50)) as "Bipad",	
							CAST(NULL as nvarchar(50)) as "LegacySystemStoreIdentifier",
							CAST(NULL as nvarchar(50)) as "ChainIdentifier",				
							CAST(NULL as nvarchar(50)) as "StoreName",
							CAST(NULL as nvarchar(100)) as "Address",
							CAST(NULL as nvarchar(50)) as "City",
							CAST(NULL as nvarchar(50)) as "State",
							CAST(NULL as nvarchar(50)) as "ZipCode",
							CAST(NULL as nvarchar(225)) as "TitleName"
							into ##tempDataUpdateActiveFinalData 
						from
						(select * FROM 
							(SELECT * from ##tempDataUpdateActiveDraws ) p
							 pivot( sum(Qty) for  wDay in
							  (MondayDraw,TuesdayDraw,WednesdayDraw,ThursdayDraw,
							  FridayDraw,SaturdayDraw,SundayDraw)) as Draw_eachday
						) tmpdraws '
						
				
				exec(@strquery)
				
				--Update the required fields
		
		set @strquery='update f set 
						f.StoreNumber=(select distinct StoreIdentifier from dbo.Stores 
						where StoreID=f.StoreID),
						f.ChainIdentifier=(select distinct ChainIdentifier from dbo.Chains 
						where Chainid=f.ChainID),
						f.Bipad=(select distinct bipad from dbo.ProductIdentifiers 
						where Productid=f.Productid),
						f.TitleName=(select distinct Bipad from dbo.ProductIdentifiers
						where Productid=f.Productid),
						f.LegacySystemStoreIdentifier=(select distinct LegacySystemStoreIdentifier from dbo.Stores 
						where StoreID=f.StoreID),
						f.StoreName=(select distinct StoreName from dbo.Stores  
						where StoreID=f.StoreID),				
						f.address=(select distinct Address1 from dbo.Addresses 
						where OwnerEntityID=f.StoreID),
						f.city=(select distinct city from dbo.Addresses where OwnerEntityID=f.StoreID),
						f.state=(select distinct state from dbo.Addresses where OwnerEntityID=f.StoreID),
						f.zipcode=(select distinct PostalCode from dbo.Addresses
						where OwnerEntityID=f.StoreID),
						f.WeekEnding=(select distinct top 1 Saledatetime from dbo.Storetransactions_forward where supplierid=f.supplierid and chainid=f.chainid and storeid=f.StoreID and productid=f.productid and TransactionTypeID in (29)  )
						
						from ##tempDataUpdateActiveFinalData f'
					
						exec(@strquery)
						
		--Return the Data	
		
		
		SET @sqlQueryStorenewDB='SELECT distinct ChainIdentifier as chainid,StoreNumber, LegacySystemStoreIdentifier as StoreId, StoreName, Address, City, State, ZipCode,Weekending from ##tempDataUpdateActiveFinalData'			
	
		
		
		set @sqlQueryNew = 'select distinct (''Store : '' + StoreNumber + '','' 
						+ Address + '','' + State + '','' + ChainIdentifier + '', Store # :  '' + StoreNumber + '' /n Location : '' + City + '', 
						'' + Address + '','' + State + '', '' + ZipCode +'', Week Ending :''+ + Convert(varchar,Weekending,101)) as StoreInfo,  ChainIdentifier as chainid,LegacySystemStoreIdentifier as StoreId,StoreNumber, StoreName, Address, City, State, ZipCode , Bipad ,TitleName,
							mondaydraw as mon ,tuesdaydraw as tue,wednesdaydraw as wed,thursdaydraw as thur,
							fridaydraw as fri,saturdaydraw as sat,sundaydraw as sun,Convert(varchar,Weekending,101) as Weekending,1 as dbType

							from ##tempDataUpdateActiveFinalData'				
			END
if(@DBType=2)
	begin
		--set @sqlQueryFinal=@sqlQueryStoreLegacy+ ' union ' +@sqlQueryStorenewDB
		--print(@sqlQueryFinal)
		--EXEC(@sqlQueryFinal)
		set @sqlQueryFinal=@sqlQueryLegacy+ ' union ' +@sqlQueryNew
		print(@sqlQueryFinal)
		EXEC(@sqlQueryFinal)
	end
else IF(@DBType=1)
	begin
	--print(@sqlQueryStorenewDB)
	--	EXEC(@sqlQueryStorenewDB)
		print(@sqlQueryNew)
		EXEC(@sqlQueryNew)
end
else IF(@DBType=0)
	begin
	--print(@sqlQueryStoreLegacy)
	--	EXEC(@sqlQueryStoreLegacy)
		print(@sqlQueryLegacy)
		EXEC(@sqlQueryLegacy)
	end			
END
GO
