USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_DefaultCostListPDI]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec  [usp_DefaultCostListPDI] '76237','79370','-1',1,'2','like','','1','like','','1','like','','','','-1','S.SupplierName ASC',1,25,0,'2'
-- exec usp_DefaultCostListPDI '-1','62597','VOLTA',0,2,'',1,'',1,'','Retailer ASC',1,25,0
-- usp_DefaultCostListPDI '-1','64010','Lehigh Gas',1,2,'',1,'923',1,'','','','Supplier ASC',1,25,0
-- usp_DefaultCostListPDI '64422','64010','Lehigh Gas',1,2,'',1,'923',1,'','','','Supplier ASC',1,25,0
-- usp_DefaultCostListPDI '28816','64010','Lehigh Gas',1,2,'',1,'',1,'','','','T.[Cost Type] ASC',1,25,0
CREATE procedure [dbo].[usp_DefaultCostListPDI]
	@SupplierId varchar(5),
	@ChainId varchar(5),
	@custom1 varchar(255),
	@WithStore int,
	@ProductIdentifierType int,
	@ProductIdentifierContains varchar(20),
	@ProductIdentifierValue varchar(250),
	@StoreIdentifierType int,
	@StoreIdentifierContains varchar(20),
	@StoreIdentifierValue varchar(50),
	@OtherOption int,
	@OtherContains varchar(20),
	@Others varchar(50),
	@SupplierIdentifierValue varchar(50),
	@RetailerIdentifierValue varchar(50),
	@Category Varchar(20),
	@StoreStatus Varchar(20),
	@OrderBy varchar(100),
	@StartIndex int,
	@PageSize int,
	@DisplayMode int
	
as

Begin
		Declare @sqlQuery varchar(8000)
		Declare @CostFormat varchar(10)

		if(@supplierID<>'-1')
			Select @CostFormat = Costformat from SupplierFormat where SupplierID = @supplierID
		else
			set @CostFormat=4
		set @Costformat = isnull(@CostFormat,3 )
		
		set @sqlQuery = 'SELECT  [Retailer] as [Retailer Name], Supplier as [Supplier Name],S.SupplierIdentifier as [Supplier Identifier], T.Banner , ProductDescription as [Product Description], Brand, Product, '

		if (@WithStore=1)              
			set @sqlQuery = @sqlQuery +  ' [DistributionCenter] as [Distribution Center], [RegionalMgr] as [Regional Mgr], SalesRep as  [Sales Rep],  [Supplier Acct Number], [Driver Name], [Route Number], [Store Number], [SBT Number], '

		set @sqlQuery = @sqlQuery +  ' dbo.trim(UPC) as UPC, dbo.trim([Supplier Product Code]) as [Supplier Product Code], dbo.trim([Package Desc]) AS [Package Desc],
										cast([Purchasable Unit Cost] as numeric(10,' + @CostFormat + ')) as [Purchasable Unit Cost],  
										cast([Purchasable Unit Retail] as numeric(10,' + @CostFormat + ')) as [Purchasable Unit Retail], 
										cast([Sellable Unit Cost] as numeric(10,' + @CostFormat + ')) as [Sellable Unit Cost],  
										cast([Sellable Unit Retail] as numeric(10,' + @CostFormat + ')) as [Sellable Unit Retail], 
										PricePriority as [Price Priority], 
										Convert(varchar(10),[Begin Date], 101) as [Begin Date], 
										Convert(varchar(10), [End Date], 101) as [End Date],
										cast(T.[Cost Type] as varchar) as [Cost Type],
										PD1.Bipad as [Bipad],S.SupplierIdentifier as [Wholesaler ID #] '
										
		if (@WithStore=1) 			
			set @sqlQuery = @sqlQuery + ', CZ.CostZoneName as [Cost Zone Name] FROM  DataTrue_CustomResultSets.dbo.[tmpDefaultCostsPDI] T '
		else 
			set @sqlQuery = @sqlQuery + ' FROM  DataTrue_CustomResultSets.dbo.[tmpDefaultCostsPDI_Product] T with (nolock) '
		
		set @sqlQuery = @sqlQuery + ' Inner join Suppliers S with (nolock) on S.SupplierId = T.SupplierId '
		set @sqlQuery = @sqlQuery + ' Inner join Chains C with (nolock) on C.ChainID = T.ChainId '
		set @sqlQuery = @sqlQuery + ' Inner join SupplierBanners SB with (nolock) on SB.SupplierId = T.SupplierId and SB.Status=''Active'' and SB.Banner=T.Banner '
		set @sqlQuery = @sqlQuery + ' Left JOIN dbo.ProductIdentifiers PD1 with(nolock) ON T.ProductID = PD1.ProductID  AND PD1.ProductIdentifierTypeID=8 and T.UPC=pd1.IdentifierValue '
		
		if (@WithStore=1)
			set @sqlQuery = @sqlQuery + ' Left Join (Select CZ.CostZoneName, CZR.SupplierID, CZR.StoreID from CostZoneRelations CZR  with (nolock)
														Inner Join CostZones CZ  with (nolock)on CZ.CostZoneID=CZR.CostZoneID
													 ) as CZ on CZ.SupplierID=T.SupplierID and CZ.StoreID=T.StoreId '
		
		set @sqlQuery = @sqlQuery + ' WHERE 1=1 '		
		
		if(@SupplierId<>'-1')
			set @sqlQuery = @sqlQuery +  ' and T.SupplierID=' + @SupplierId

		if(@ChainId<>'-1')
			set @sqlQuery = @sqlQuery +  ' and T.ChainId=' + @ChainId

		if(@SupplierIdentifierValue<>'')
			set @sqlQuery = @sqlQuery + ' and S.SupplierIdentifier like ''%' + @SupplierIdentifierValue + '%'''
		
		if(@RetailerIdentifierValue<>'')
			set @sqlQuery = @sqlQuery + ' and C.ChainIdentifier like ''%' + @RetailerIdentifierValue + '%'''
				
		if(@custom1='')
			set @sqlQuery = @sqlQuery + ' and T.Banner is Null'

		else if(@custom1<>'-1')
			set @sqlQuery = @sqlQuery + ' and T.Banner=''' + @custom1 + ''''
			
		if(@StoreStatus='1')
			set @sqlQuery = @sqlQuery +  ' AND getdate() BETWEEN  Convert(varchar(10),T.[Begin Date], 101) AND Convert(varchar(10),T.[End Date], 101) '
		else if(@StoreStatus='2')
			set @sqlQuery = @sqlQuery +  ' AND getdate() > Convert(varchar(10),T.[End Date], 101)'	

		if(@ProductIdentifierValue<>'')
		begin
			-- 2 = UPC, 3 = Product Name , 7 = Supplier Product Code
			IF(@ProductIdentifierContains <> '')
				BEGIN
					IF(@ProductIdentifierContains = 'LIKE')
						BEGIN
							if (@ProductIdentifierType=2)
								set @sqlQuery = @sqlQuery + ' and  UPC ' + @ProductIdentifierContains + ' ''%' + @ProductIdentifierValue + '%'''

							else if (@ProductIdentifierType=3)
								set @sqlQuery = @sqlQuery + ' and Product ' + @ProductIdentifierContains + ' ''%' + @ProductIdentifierValue + '%'''

							else if (@ProductIdentifierType=7)
								set @sqlQuery = @sqlQuery + ' and dbo.trim([Supplier Product Code]) ' + @ProductIdentifierContains + ' ''%' + @ProductIdentifierValue + '%'''
				
							else if (@ProductIdentifierType=8)
								set @sqlQuery = @sqlQuery + ' and PD1.Bipad ' + @ProductIdentifierContains + ' ''%' + @ProductIdentifierValue + '%'''
						END
					ELSE
						BEGIN
							if (@ProductIdentifierType=2)
								set @sqlQuery = @sqlQuery + ' and  UPC ' + @ProductIdentifierContains + ' '''  + @ProductIdentifierValue +''''

							else if (@ProductIdentifierType=3)
								set @sqlQuery = @sqlQuery + ' and Product ' + @ProductIdentifierContains + ' '''  + @ProductIdentifierValue +''''

							else if (@ProductIdentifierType=7)
								set @sqlQuery = @sqlQuery + ' and dbo.trim([Supplier Product Code]) ' + @ProductIdentifierContains + '  '''  + @ProductIdentifierValue +''''
				
							else if (@ProductIdentifierType=8)
								set @sqlQuery = @sqlQuery + ' and PD1.Bipad  ' + @ProductIdentifierContains + '  '''  + @ProductIdentifierValue +''''
						END
				END
		END

		if(@StoreIdentifierValue<>'')
		begin
			-- 1 = Store Number, 2 = SBT Number, 3 = Store Name
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
		END

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
							set @sqlQuery = @sqlQuery + ' and [Route Number] ' + @OtherOption + ' '''  + @Others +''''
					END
				END
		END


		if(@Category='1')
			set @sqlQuery = @sqlQuery +  ' and T.ProductIdentifierTypeId=8'
		else if(@Category='2')
			set @sqlQuery = @sqlQuery +  ' and T.ProductIdentifierTypeId<>8'	
				
		--set @sqlQuery = @sqlQuery + ' order by Stores.storename,saledate';
		print (@sqlQuery)
		set @sqlQuery = [dbo].GetPagingQuery_New(@sqlQuery, @OrderBy, @StartIndex ,@PageSize ,@DisplayMode)
		
		exec (@sqlQuery)
		

End
GO
