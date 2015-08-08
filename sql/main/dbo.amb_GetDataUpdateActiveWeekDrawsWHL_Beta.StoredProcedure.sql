USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_GetDataUpdateActiveWeekDrawsWHL_Beta]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--select * from dbo.suppliers where supplierIdentifier='ENT'
-- exec amb_GetDataUpdateActiveWeekDrawsWHL 'ENT','24178','-1','-1','KNG3900','11/06/2012'
-- exec amb_GetDataUpdateActiveWeekDrawsWHL 'WR1428','24503','-1','-1','','1900-01-01'
--exec amb_GetDataUpdateActiveWeekDrawsWHL_Beta 'CLL','24164','DQ','-1','','09/15/2013'

--exec amb_GetDataUpdateActiveWeekDrawsWHL_Beta 'WR651','26582','CF','-1','','01/05/2015'

--'11/11/2012'

CREATE procedure [dbo].[amb_GetDataUpdateActiveWeekDrawsWHL_Beta]
(
  @SupplierIdentifier varchar(10),
	@SupplierId varchar(20),
	@ChainID varchar(10),
	@State varchar(10),
	@StoreNumber varchar(10),
	@WeekEnd varchar(50)
	/*@OrderBy varchar(100),
	@StartIndex int,
	@PageSize int,
	@DisplayMode int*/
)
as 
BEGIN	
	
	DECLARE @sqlQueryNew VARCHAR(8000)
	

			--Get the data in to tmp table for draws
			
				if object_id('tempdb.dbo.##tempDataUpdateActiveDraws') is not null
					begin
						drop table ##tempDataUpdateActiveDraws;
					end
				declare @strquery varchar(8000)
				set @strquery= 'select  st.ChainID,
								st.SupplierID,
								s.storeid,
								st.ProductID,
								Qty,
								Convert(varchar(12),dbo.GetWeekEnd_TimeOutFix(ST.SaleDateTime, BC.BillingControlDay),101) WeekEnding,
								TransactionTypeID,
								datename(W,SaleDateTime)+ ''Draw'' as "wDay",
								S.StoreIdentifier AS StoreNumber,
								S.LegacySystemStoreIdentifier,
								C.ChainIdentifier,				
							    S.StoreName,
							    A.Address1 AS Address,
								A.City,
							    A.State,
							    A.PostalCode AS ZipCode
								
								
								into ##tempDataUpdateActiveDraws
								
							FROM dbo.Storetransactions_forward st with (nolock) 
								INNER JOIN dbo.Chains c  with (nolock) on st.ChainID=c.ChainID
								INNER JOIN dbo.Stores s  with (nolock) ON s.StoreID=st.StoreID and s.ChainID=c.ChainID
								INNER JOIN dbo.Addresses a  with (nolock) ON a.OwnerEntityID=st.StoreID
								LEFT JOIN DataTrue_Main.dbo.BillingControl BC WITH (NOLOCK) ON BC.EntityIDToInvoice = ST.SupplierID AND BC.ChainID = C.ChainID
								 
								where TransactionTypeID in (29) 
								and st.supplierid=' + @SupplierId + ' 
								and s.LegacySystemStoreIdentifier like ''%'+@StoreNumber+'%''' 
	
			if(@ChainID<>'-1')					
				set @strquery = @strquery +' and c.ChainIdentifier='''+@ChainID+''''
			
			if(@State<>'-1')    
				set @strquery = @strquery +' and a.State like '''+@State+''''
									
			if(CAST(@WeekEnd as DATE) <> CAST('1900-01-01' as DATE))
				set @strquery = @strquery +' and CAST(dbo.GetWeekEnd_TimeOutFix(ST.SaleDateTime, BC.BillingControlDay) AS DATE) =  cast (''' +@WeekEnd + ''' as DATE) '		
			EXEC(@strquery)
				
				
		if object_id('tempdb.dbo.##tempDataUpdateActiveFinalData') is not null
			begin
			drop table ##tempDataUpdateActiveFinalData	
		end						
													
		set @strquery='Select distinct tmpdraws.*,
						    CAST(NULL as nvarchar(50)) as "Bipad",	
							CAST(NULL as nvarchar(500)) as "TitleName"
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
						--f.StoreNumber=(select distinct StoreIdentifier from dbo.Stores where StoreID=f.StoreID),
						--f.ChainIdentifier=(select distinct ChainIdentifier from dbo.Chains where Chainid=f.ChainID),
						f.Bipad=(select distinct bipad from dbo.ProductIdentifiers where Productid=f.Productid and productidentifiertypeid in(2,8)),
						f.TitleName=(select distinct ProductName from dbo.Products where Productid=f.Productid )
						--f.LegacySystemStoreIdentifier=(select distinct LegacySystemStoreIdentifier from dbo.Stores where StoreID=f.StoreID),
						--f.StoreName=(select distinct StoreName from dbo.Stores where StoreID=f.StoreID),				
						--f.address=(select distinct Address1 from dbo.Addresses where OwnerEntityID=f.StoreID),
						--f.city=(select distinct city from dbo.Addresses where OwnerEntityID=f.StoreID),
						--f.state=(select distinct state from dbo.Addresses where OwnerEntityID=f.StoreID),
						--f.zipcode=(select distinct PostalCode from dbo.Addresses where OwnerEntityID=f.StoreID)
						--f.WeekEnding=(select distinct top 1 Convert(varchar(12),Saledatetime,101) from dbo.Storetransactions_forward where supplierid=f.supplierid and chainid=f.chainid and storeid=f.StoreID and productid=f.productid and TransactionTypeID in (29)  )
						
						from ##tempDataUpdateActiveFinalData f'
						exec(@strquery)
						
		--Return the Data	
	set @sqlQueryNew = 'select  distinct  (LegacySystemStoreIdentifier + '', Site # '' + StoreNumber + '' /n Location : '' + City + '', '' + Address + '','' + State + '', '' + ZipCode +'', 
							Week Ending :''+  Weekending ) as StoreInfo,											
							ChainIdentifier as chainid,
							LegacySystemStoreIdentifier as StoreId,
							StoreNumber, 
							StoreName, 
							Address, 
							City, 
							State, 
							ZipCode , 
							Bipad ,
							TitleName,
							isnull(mondaydraw,0) as mon ,
							isnull(tuesdaydraw,0) as tue,
							isnull(wednesdaydraw,0) as wed,
							isnull(thursdaydraw,0) as thur,
							isnull(fridaydraw,0) as fri,
							isnull(saturdaydraw,0) as sat,
							isnull(sundaydraw,0) as sun,
							Convert(varchar,Weekending,101) as Weekending,
							1 as dbType

							from ##tempDataUpdateActiveFinalData 
							
							Order By LegacySystemStoreIdentifier,TitleName '				
		
		
	    exec (@sqlQueryNew)	
	    
	if object_id('tempdb.dbo.##tempDataUpdateActiveDraws') is not null
					begin
						drop table ##tempDataUpdateActiveDraws;
					end
					
			if object_id('tempdb.dbo.##tempDataUpdateActiveFinalData') is not null
			begin
			drop table ##tempDataUpdateActiveFinalData	
		end				
						
END
GO
