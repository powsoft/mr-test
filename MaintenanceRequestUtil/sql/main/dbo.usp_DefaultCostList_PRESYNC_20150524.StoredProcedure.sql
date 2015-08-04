USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_DefaultCostList_PRESYNC_20150524]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec  [usp_DefaultCostListNew] '40559','40393','-1',1,2,'',1,'',1,'', 'Supplier',1,25,0
--usp_DefaultCostList -1,74628,'-1',1,2,'Like','827912030457',1,'Like','','1','1','','','','T.Banner ASC',1,25,0
-- usp_DefaultCostList 40557,60620,'-1',0,2,'Like','',1,'Like','',1,'Like','','','','Supplier ASC',1,25,0
CREATE procedure [dbo].[usp_DefaultCostList_PRESYNC_20150524]
	@SupplierId varchar(5),
	@ChainId varchar(5),
	@custom1 varchar(255),
	@WithStore int,
	@ProductIdentifierType int,
	@ProductIdentifierContains varchar(20),
	@ProductIdentifierValue varchar(250),
	@StoreIdentifierType int,
	@StoreIdentifierContains varchar(20),
	@StoreIdentifierValue varchar(250),
	@OtherOption int,
	@OtherContains varchar(20),
	@Others varchar(250),
	@SupplierIdentifierValue varchar(50),
	@RetailerIdentifierValue varchar(50),
	@Category varchar(20),
	@OrderBy varchar(100),
	@StartIndex int,
	@PageSize int,
	@DisplayMode int
as

Begin
		Declare @sqlQuery varchar(4000)
		Declare @CostFormat varchar(10)

		if(@supplierID<>'-1')
			Select @CostFormat = Costformat from SupplierFormat where SupplierID = @supplierID
		else
			set @CostFormat=4
		set @Costformat = isnull(@CostFormat,3 )
		
		set @sqlQuery = 'SELECT  [Retailer] as [Retailer Name], Supplier as [Supplier Name], T.Banner , ProductDescription as [Product Description], Brand, Product, '

		if (@WithStore=1)              
			set @sqlQuery = @sqlQuery +  ' [DistributionCenter] as [Distribution Center], [RegionalMgr] as [Regional Mgr], SalesRep as  [Sales Rep],  [Supplier Acct Number], [Driver Name], [Route Number], [Store Number], [SBT Number], '
			

		set @sqlQuery = @sqlQuery +  ' dbo.trim(UPC) as UPC, dbo.trim([Supplier Product Code]) as [Supplier Product Code], 
										cast([Unit Cost] as numeric(10,' + @CostFormat + ')) as [Unit Cost],  
										cast([Unit Retail] as numeric(10,2)) as [Unit Retail], PricePriority as [Price Priority], 
										Convert(varchar(10),[Begin Date], 101) as [Begin Date], Convert(varchar(10), [End Date], 101) as [End Date],
										T.Bipad as [Bipad], SP.SupplierIdentifier as [Wholesaler ID] '
		if (@WithStore=1) 			
			set @sqlQuery = @sqlQuery + ', CZ.CostZoneName as [Cost Zone Name] FROM  DataTrue_CustomResultSets.dbo.[tmpDefaultCosts] T '
		else 
			set @sqlQuery = @sqlQuery + ' FROM  DataTrue_CustomResultSets.dbo.[tmpDefaultCosts_Product] T '
			
		set @sqlQuery = @sqlQuery + ' Inner join SupplierBanners SB on SB.SupplierId = T.SupplierId and SB.Status=''Active'' and SB.Banner=T.Banner '
		
		if (@WithStore=1)
			set @sqlQuery = @sqlQuery + ' Left Join (Select CZ.CostZoneName, CZR.SupplierID, CZR.StoreID from CostZoneRelations CZR 
														Inner Join CostZones CZ on CZ.CostZoneID=CZR.CostZoneID
													 ) as CZ on CZ.SupplierID=T.SupplierID and CZ.StoreID=T.StoreId '
													 
		set @sqlQuery = @sqlQuery + ' Inner join Suppliers SP on SP.SupplierId = T.SupplierId '
		
		set @sqlQuery = @sqlQuery + ' WHERE 1=1 '		
		
		if(@SupplierId<>'-1')
			set @sqlQuery = @sqlQuery +  ' and T.SupplierID=' + @SupplierId

		if(@ChainId<>'-1')
			set @sqlQuery = @sqlQuery +  ' and T.ChainId=' + @ChainId

		if(@custom1='')
			set @sqlQuery = @sqlQuery + ' and T.Banner is Null'

		else if(@custom1<>'-1')
			set @sqlQuery = @sqlQuery + ' and T.Banner=''' + @custom1 + ''''

		if(@ProductIdentifierValue<>'')
		begin

			-- 2 = UPC, 3 = Product Name , 7 = Vendor Item Number
			IF(@ProductIdentifierContains <> '')
				BEGIN
					IF(@ProductIdentifierContains = 'LIKE')
						BEGIN
							if (@ProductIdentifierType=2)
								set @sqlQuery = @sqlQuery + ' and  UPC ' + @ProductIdentifierContains + ' ''%' + @ProductIdentifierValue + '%'''

							else if (@ProductIdentifierType=3)
								set @sqlQuery = @sqlQuery + ' and Productid in (select productid from products where productname ' + @ProductIdentifierContains + ' ''' + @ProductIdentifierValue + '%'')'

							else if (@ProductIdentifierType=7)
								set @sqlQuery = @sqlQuery + ' and dbo.trim([Supplier Product Code]) ' + @ProductIdentifierContains + ' ''%' + @ProductIdentifierValue + '%'''
				
							--else if (@ProductIdentifierType=8)
							--	set @sqlQuery = @sqlQuery + ' and Bipad ' + @ProductIdentifierContains + ' ''%' + @ProductIdentifierValue + '%'''
						END
					ELSE
						BEGIN
							if (@ProductIdentifierType=2)
								set @sqlQuery = @sqlQuery + ' and  UPC ' + @ProductIdentifierContains + ' '''  + @ProductIdentifierValue +''''

							else if (@ProductIdentifierType=3)
								set @sqlQuery = @sqlQuery + ' and Product ' + @ProductIdentifierContains + ' '''  + @ProductIdentifierValue +''''

							else if (@ProductIdentifierType=7)
								set @sqlQuery = @sqlQuery + ' and dbo.trim([Supplier Product Code]) ' + @ProductIdentifierContains + '  '''  + @ProductIdentifierValue +''''
				
							--else if (@ProductIdentifierType=8)
							--	set @sqlQuery = @sqlQuery + ' and Bipad  ' + @ProductIdentifierContains + '  '''  + @ProductIdentifierValue +''''
						END
				END
		end

		if(@StoreIdentifierValue<>'')
		begin
			-- 1 = Store Number, 2 = SBT Number, 3 = Store Name, 
			IF(@StoreIdentifierContains <> '')
				BEGIN
					IF(@StoreIdentifierContains = 'LIKE')
						BEGIN
							if (@StoreIdentifierType=1)
								set @sqlQuery = @sqlQuery + ' and [Store Number] ' + @StoreIdentifierContains + ' ''%' + @StoreIdentifierValue + '%'''
							else if (@StoreIdentifierType=2)
								set @sqlQuery = @sqlQuery + ' and [SBT Number] ' + @StoreIdentifierContains + ' ''%' + @StoreIdentifierValue + '%'''
							else if (@StoreIdentifierType=3)
								set @sqlQuery = @sqlQuery + ' and StoreName ' + @StoreIdentifierContains + ' ''%' + @StoreIdentifierValue + '%'''
						END
					ELSE
						BEGIN
							if (@StoreIdentifierType=1)
								set @sqlQuery = @sqlQuery + ' and [Store Number] ' + @StoreIdentifierContains + ' '''  + @StoreIdentifierValue +''''
							else if (@StoreIdentifierType=2)
								set @sqlQuery = @sqlQuery + ' and [SBT Number] ' + @StoreIdentifierContains + ' '''  + @StoreIdentifierValue +''''
							else if (@StoreIdentifierType=3)
								set @sqlQuery = @sqlQuery + ' and StoreName ' + @StoreIdentifierContains + ' '''  + @StoreIdentifierValue +''''
						END
				END
		end

		if(@Others<>'')
		begin
			-- 1 = Distribution Center, 2 = Regional Manager, 3 = Sales Representative
			-- 4 = Supplier Account No, 5 = Driver Name, 6 = Route No
			IF(@OtherContains <> '')
			BEGIN
				IF(@OtherContains  = 'LIKE')
					BEGIN
						if (@OtherOption=1)
							set @sqlQuery = @sqlQuery + ' and [DistributionCenter] ' + @OtherContains + ' ''%' + @Others + '%'''
						else if (@OtherOption=2)
							set @sqlQuery = @sqlQuery + ' and [RegionalMgr] ' + @OtherContains + ' ''%' + @Others + '%'''
						else if (@OtherOption=3)
							set @sqlQuery = @sqlQuery + ' and [SalesRep] ' + @OtherContains + ' ''%' + @Others + '%'''
						else if (@OtherOption=4)
							set @sqlQuery = @sqlQuery + ' and [Supplier Acct Number] ' + @OtherContains + ' ''%' + @Others + '%'''
						else if (@OtherOption=5)
							set @sqlQuery = @sqlQuery + ' and [Driver Name] ' + @OtherContains + ' ''%' + @Others + '%'''
						else if (@OtherOption=6)
							set @sqlQuery = @sqlQuery + ' and [Route Number] ' + @OtherContains + ' ''%' + @Others + '%'''
					END
				ELSE
					BEGIN
						if (@OtherOption=1)
							set @sqlQuery = @sqlQuery + ' and [DistributionCenter] ' + @OtherContains + ' '''  + @Others +''''
						else if (@OtherOption=2)
							set @sqlQuery = @sqlQuery + ' and [RegionalMgr] ' + @OtherContains + ' '''  + @Others +''''
						else if (@OtherOption=3)
							set @sqlQuery = @sqlQuery + ' and [SalesRep] ' + @OtherContains + ' '''  + @Others +''''
						else if (@OtherOption=4)
							set @sqlQuery = @sqlQuery + ' and [Supplier Acct Number] ' + @OtherContains + ' '''  + @Others +''''
						else if (@OtherOption=5)
							set @sqlQuery = @sqlQuery + ' and [Driver Name] ' + @OtherContains + ' '''  + @Others +''''
						else if (@OtherOption=6)
							set @sqlQuery = @sqlQuery + ' and [Route Number] ' + @OtherContains + ' '''  + @Others +''''
					END
				END
			END
			

		if(@Category='1')
			set @sqlQuery = @sqlQuery +  ' and ProductIdentifierTypeId=8'
		else if(@Category='2')
			set @sqlQuery = @sqlQuery +  ' and ProductIdentifierTypeId<>8'	
		
		--set @sqlQuery = @sqlQuery + ' order by Stores.storename,saledate';
		set @sqlQuery = [dbo].GetPagingQuery_New(@sqlQuery, @OrderBy, @StartIndex ,@PageSize ,@DisplayMode)

		exec (@sqlQuery)
		print (@sqlQuery)
End
GO
