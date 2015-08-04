USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_SaleForecastReport]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- exec  [usp_SaleForecastReport] 40393, 40557, 'Albertsons - SCAL', 60, 2, 2, '', 2, ''
CREATE procedure [dbo].[usp_SaleForecastReport]
 @ChainId varchar(5),
 @SupplierID varchar(5),
 @custom1 varchar(255),
 @OldDays int,
 @POSWeeks int,
 @ProductIdentifierType int,
 @ProductIdentifierValue varchar(50),
 @StoreIdentifierType int,
 @StoreIdentifierValue varchar(50)
as
Begin

	exec [usp_GenerateSaleForecastData] @ChainId, @SupplierID, @custom1, @OldDays, @POSWeeks 
	
	Declare @TransDate varchar(2000)
	Declare @sqlQuery varchar(8000), @recCount numeric(10)
	select @recCount=COUNT([Transaction Date]) from DataTrue_CustomResultSets.dbo.tmpSaleForecast
	
	if(@recCount=0)
		select COUNT([Transaction Date]) from DataTrue_CustomResultSets.dbo.tmpSaleForecast
	else
	begin
		
		select @TransDate = COALESCE(@TransDate+'],[' ,'') + CAST( [Transaction Date] as varchar(10))
		from DataTrue_CustomResultSets.dbo.tmpSaleForecast 
		where [Transaction Date]>getdate()
		group by [Transaction Date] order by [Transaction Date] asc
		
		begin try
			Drop Table [@tmpSaleData]
		end try
		begin catch
		end catch
			
		set @sqlQuery='
					SELECT * into [@tmpSaleData] FROM
					(
					  SELECT ChainID, SupplierId, StoreID, ProductID,[Transaction Date], [Forecast Units]
					  FROM DataTrue_CustomResultSets.dbo.tmpSaleForecast 
					) TableDate

					PIVOT 
					(
					  sum([Forecast Units])  FOR [Transaction Date] IN ([' + @TransDate + '])
					) PivotTable
					
					order by ChainID, SupplierId, StoreID, ProductID	'
		
		exec(@sqlQuery)
		
		set @sqlQuery = 'select C.ChainName as [Retailer Name], SP.SupplierName as [Supplier Name],
						S.Custom1 as Banner, S.StoreIdentifier as [Store Number], P.ProductName as [Product Name],
						PD.IdentifierValue as [UPC], t.* 
						from  [@tmpSaleData] t 
						INNER JOIN Stores S ON S.StoreID = t.StoreID and S.ActiveStatus=''Active'' 
						INNER JOIN Products P ON P.ProductId = t.ProductId 
						INNER JOIN Suppliers SP ON SP.SupplierId = t.SupplierId
						INNER JOIN Chains C ON C.ChainId = t.ChainId
						INNER JOIN ProductIdentifiers PD ON PD.ProductID = P.ProductID 
						inner join SupplierBanners SB on SB.SupplierId = SP.SupplierId and SB.Status=''Active'' and SB.Banner=S.Custom1
						where 1=1 '
		
		if(@ChainId <>'-1') 
			set @sqlQuery = @sqlQuery +  ' and C.ChainID=' + @ChainId

		if(@SupplierID <>'-1') 
			set @sqlQuery = @sqlQuery +  ' and t.supplierid=' + @SupplierId
		
		if(@ProductIdentifierType<>3)
				set @sqlQuery = @sqlQuery + ' and PD.ProductIdentifierTypeId =' + cast(@ProductIdentifierType as varchar)
		else
				set @sqlQuery = @sqlQuery + ' and PD.ProductIdentifierTypeId = 2'
				
		if(@ProductIdentifierValue<>'')
		begin
			-- 2 = UPC, 3 = Product Name 
			if (@ProductIdentifierType=2)
				 set @sqlQuery = @sqlQuery + ' and PD.IdentifierValue like ''%' + @ProductIdentifierValue + '%'''
		         
			else if (@ProductIdentifierType=3)
				set @sqlQuery = @sqlQuery + ' and P.ProductName like ''%' + @ProductIdentifierValue + '%'''
		end
	 
		if(@StoreIdentifierValue<>'')
		begin
			-- 1 = Store Number, 2 = SBT Number, 3 = Store Name
			if (@StoreIdentifierType=1)
				set @sqlQuery = @sqlQuery + ' and S.storeidentifier like ''%' + @StoreIdentifierValue + '%'''
			else if (@StoreIdentifierType=2)
				set @sqlQuery = @sqlQuery + ' and S.Custom2 like ''%' + @StoreIdentifierValue + '%'''
			else if (@StoreIdentifierType=3)
				set @sqlQuery = @sqlQuery + ' and S.StoreName like ''%' + @StoreIdentifierValue + '%'''
		end
		
		set @sqlQuery = @sqlQuery + ' ORDER BY 1,2,3,4,5,6'
		exec(@sqlQuery); 
	end
End
GO
