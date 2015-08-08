USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_DefaultCostListNew]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec  [usp_DefaultCostListNew] '40559','40393','-1',1,2,'',1,'',1,'', 'Supplier',1,25,0
CREATE procedure [dbo].[usp_DefaultCostListNew]
	@SupplierId varchar(5),
	@ChainId varchar(5),
	@custom1 varchar(255),
	@WithStore int,
	@ProductIdentifierType int,
	@ProductIdentifierValue varchar(50),
	@StoreIdentifierType int,
	@StoreIdentifierValue varchar(50),
	@OtherOption int,
	@Others varchar(50),
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
		set @Costformat = isnull(@CostFormat,0 )
		
		set @sqlQuery = 'SELECT  [Retailer] as [Retailer Name], Supplier as [Supplier Name], T.Banner , ProductDescription as [Product Description], Brand, Product, '

		if (@WithStore=1)              
			set @sqlQuery = @sqlQuery +  ' [DistributionCenter] as [Distribution Center], [RegionalMgr] as [Regional Mgr], SalesRep as  [Sales Rep],  [Supplier Acct Number], [Driver Name], [Route Number], [Store Number], [SBT Number], '

		set @sqlQuery = @sqlQuery +  ' dbo.trim(UPC) as UPC, dbo.trim([Supplier Product Code]) as [Supplier Product Code], 
										cast([Unit Cost] as numeric(10,' + @CostFormat + ')) as [Unit Cost],  
										cast([Unit Retail] as numeric(10,2)) as [Unit Retail], PricePriority as [Price Priority], 
										Convert(datetime,[Begin Date], 101) as [Begin Date], Convert(datetime, [End Date], 101) as [End Date] '
		if (@WithStore=1) 			
			set @sqlQuery = @sqlQuery + ', CZ.CostZoneName as [Cost Zone Name] FROM  DataTrue_CustomResultSets.dbo.[tmpDefaultCosts] T '
		else 
			set @sqlQuery = @sqlQuery + ' FROM  DataTrue_CustomResultSets.dbo.[tmpDefaultCosts_Product] T '
			
		set @sqlQuery = @sqlQuery + ' Inner join SupplierBanners SB on SB.SupplierId = T.SupplierId and SB.Status=''Active'' and SB.Banner=T.Banner '
		
		if (@WithStore=1)
			set @sqlQuery = @sqlQuery + ' Left Join (Select CZ.CostZoneName, CZR.SupplierID, CZR.StoreID from CostZoneRelations CZR 
														Inner Join CostZones CZ on CZ.CostZoneID=CZR.CostZoneID
													 ) as CZ on CZ.SupplierID=T.SupplierID and CZ.StoreID=T.StoreId '
		
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

			-- 2 = UPC, 3 = Product Name , 7 = Supplier Product Code
			if (@ProductIdentifierType=2)
				set @sqlQuery = @sqlQuery + ' and UPC like ''%' + @ProductIdentifierValue + '%'''

			else if (@ProductIdentifierType=3)
				set @sqlQuery = @sqlQuery + ' and Product like ''%' + @ProductIdentifierValue + '%'''

			else if (@ProductIdentifierType=7)
				set @sqlQuery = @sqlQuery + ' and [Supplier Product Code] like ''%' + @ProductIdentifierValue + '%'''
		end

		if(@StoreIdentifierValue<>'')
		begin
			-- 1 = Store Number, 2 = SBT Number, 3 = Store Name
			if (@StoreIdentifierType=1)
				set @sqlQuery = @sqlQuery + ' and [Store Number] like ''%' + @StoreIdentifierValue + '%'''
			else if (@StoreIdentifierType=2)
				set @sqlQuery = @sqlQuery + ' and [SBT Number] like ''%' + @StoreIdentifierValue + '%'''
			else if (@StoreIdentifierType=3)
				set @sqlQuery = @sqlQuery + ' and StoreName like ''%' + @StoreIdentifierValue + '%'''
		end

		if(@Others<>'')
		begin
			-- 1 = Distribution Center, 2 = Regional Manager, 3 = Sales Representative
			-- 4 = Supplier Account No, 5 = Driver Name, 6 = Route No
			     
			if (@OtherOption=1)
				set @sqlQuery = @sqlQuery + ' and [DistributionCenter] like ''%' + @Others + '%'''
			else if (@OtherOption=2)
				set @sqlQuery = @sqlQuery + ' and [RegionalMgr] like ''%' + @Others + '%'''
			else if (@OtherOption=3)
				set @sqlQuery = @sqlQuery + ' and [SalesRep] like ''%' + @Others + '%'''
			else if (@OtherOption=4)
				set @sqlQuery = @sqlQuery + ' and [Supplier Acct Number] like ''%' + @Others + '%'''
			else if (@OtherOption=5)
				set @sqlQuery = @sqlQuery + ' and [Driver Name] like ''%' + @Others + '%'''
			else if (@OtherOption=6)
				set @sqlQuery = @sqlQuery + ' and [Route Number] like ''%' + @Others + '%'''

		end

		--set @sqlQuery = @sqlQuery + ' order by Stores.storename,saledate';
		set @sqlQuery = [dbo].GetPagingQuery_New(@sqlQuery, @OrderBy, @StartIndex ,@PageSize ,@DisplayMode)

		exec (@sqlQuery)

End
GO
