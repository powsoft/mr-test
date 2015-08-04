USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_CompareFiles]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_CompareFiles]  
	@TableName nvarchar(200),
	@SupplierId varchar(20),
	@ChainId varchar(20),
	@ReportType varchar(10)
as 
Begin
	
	declare @sqlQuery varchar(2000)
	
	declare @sqlReport1 varchar(2000)
	declare @sqlReport2 varchar(2000)
	declare @sqlReport3 varchar(2000)
	declare @sqlReport4 varchar(2000)
	declare @sqlReport5 varchar(2000)
	declare @sqlReport6 varchar(2000)
					
	if (@ReportType='1')
	Begin
		
		set @sqlReport1  = 'select distinct f.Banner, f.[Product Code] as UPC, F.Description as [Item Description],
					cast(PR.UnitPrice as numeric(10,2)) as [IC Cost], 
					cast(F.[Base Cost] as numeric(10,2)) as [Retailer Cost],
					cast(PR.Allowance as numeric(10,2)) as [IC Allowance], 
					cast(F.Allowance as numeric(10,2)) as [Retailer Allowance], 
					(cast(PR.UnitPrice as numeric(10,2)) - cast(PR.Allowance as numeric(10,2))) as [IC Net], 
					(cast(F.[Base Cost] as numeric(10,2)) - cast(F.Allowance as numeric(10,2)))  as [Retailer Net],
					''Cost Difference'' as [Change Type]
					
					from ' + @TableName + ' f  
					inner Join  ProductIdentifiers p on CAST(p.IdentifierValue as varchar) =  CAST(F.[Product Code] as varchar) 
					inner join ProductPrices PR on PR.ProductID=P.ProductID 
					inner join Stores S on S.StoreId=PR.StoreId and S.Custom1=f.Banner and S.ActiveStatus=''Active''
					where isnull(F.Allowance,0)=0  and PR.ProductPriceTypeID=3 and P.ProductIdentifierTypeID=2 
					and convert(varchar(10), PR.ActiveStartDate, 101) = convert(varchar(10), F.[Cost Effective Date], 101) 
					and convert(varchar(10), PR.ActiveLastDate, 101)  = convert(varchar(10), F.[Cost End Date], 101)
					and (cast(pr.UnitPrice as numeric(10,2))-cast(f.[Base Cost] as numeric(10,2))) <>0 ' 
	
		if (@SupplierId<>'-1')						
			set @sqlReport1 = @sqlReport1 + ' and PR.SupplierId=' + @SupplierId
		
		if (@ChainId<>'-1')						
			set @sqlReport1 = @sqlReport1 + ' and PR.ChainID=' + @ChainId
			
		exec ( @sqlReport1)
	End
	
	if (@ReportType='2')
	Begin
		set @sqlReport2  = 'select distinct f.Banner, f.[Product Code] as UPC, F.Description as [Item Description],
					cast(PR.UnitPrice as numeric(10,2)) as [IC Cost], 
					cast(F.[Base Cost] as numeric(10,2)) as [Retailer Cost],
					cast(PR.Allowance as numeric(10,2)) as [IC Allowance], 
					cast(F.Allowance as numeric(10,2)) as [Retailer Allowance], 
					(cast(PR.UnitPrice as numeric(10,2)) - cast(PR.Allowance as numeric(10,2))) as [IC Net], 
					(cast(F.[Base Cost] as numeric(10,2)) - cast(F.Allowance as numeric(10,2)))  as [Retailer Net],
					''Promo Difference'' as [Change Type]
					from ' + @TableName + ' f  
					
					inner Join  ProductIdentifiers p on CAST(p.IdentifierValue as varchar) =  CAST(F.[Product Code] as varchar) 
					inner join ProductPrices PR on PR.ProductID=P.ProductID 
					inner join Stores S on S.StoreId=PR.StoreId and S.Custom1=f.Banner
					where PR.ProductPriceTypeID=8 and P.ProductIdentifierTypeID=2
					and (cast(isnull(PR.Allowance,0) as numeric(10,2)) - cast(isnull(F.allowance,0) as numeric(10,2))) <> 0 
					and convert(varchar(10), PR.ActiveStartDate, 101) = convert(varchar(10), F.[Cost Effective Date], 101) 
					and convert(varchar(10), PR.ActiveLastDate, 101)  = convert(varchar(10), F.[Cost End Date], 101) '
					
		if (@SupplierId<>'-1')						
			set @sqlReport2 = @sqlReport2 + ' and PR.SupplierId=' + @SupplierId
		
		if (@ChainId<>'-1')						
			set @sqlReport2 = @sqlReport2 + ' and PR.ChainID=' + @ChainId
		
		exec ( @sqlReport2 )
		
	End
	
	if (@ReportType='3')
	Begin
		set @sqlReport3  = 'select distinct f.Banner, f.[Product Code] as UPC, F.Description as [Item Description],
						cast(F.[Base Cost] as numeric(10,2)) as [Retailer Cost],
						cast(F.Allowance as numeric(10,2)) as [Retailer Allowance], 
						(cast(F.[Base Cost] as numeric(10,2)) - cast(F.Allowance as numeric(10,2)))  as [Retailer Net],
						''Cost not in iControl'' as [Change Type]

					from ' + @TableName + ' f  
					left Join ProductIdentifiers p on CAST(p.IdentifierValue as varchar) =  CAST(F.[Product Code] as varchar) 
					where p.IdentifierValue is null'
		
		exec ( @sqlReport3 )
	End
	
	if (@ReportType='4')
	Begin
		set @sqlReport4  = 'select distinct S.Custom1 as Banner, PF.[IdentifierValue] as UPC, PD.Description as [Item Description],
							cast(PR.UnitPrice as numeric(10,2)) as [IC Cost], 
							cast(PR.Allowance as numeric(10,2)) as [IC Allowance], 
							(cast(PR.UnitPrice as numeric(10,2)) - cast(PR.Allowance as numeric(10,2))) as [IC Net], 
							''Cost not in Retailer records'' as [Change Type]
					
					from ProductPrices PR
					left Join Products PD on PD.ProductId=PR.ProductId 
					left Join ProductIdentifiers PF on PF.ProductId=PR.ProductId  
					inner join Stores S on S.StoreId=PR.StoreId 
					
					left join ' + @TableName + ' f  on 
							CAST(PF.IdentifierValue as varchar) =  CAST(F.[Product Code] as varchar) 
							and S.Custom1=f.Banner
					where PR.ProductPriceTypeID=3 and PR.ActiveStartDate <= { fn NOW() } AND PR.ActiveLastDate >= { fn NOW() } 
					and PF.ProductIdentifierTypeID=2
					and F.[Product Code] is null
					and S.Custom1 in (Select distinct Banner from ' + @TableName + ')'

		if (@SupplierId<>'-1')						
			set @sqlReport4 = @sqlReport4 + ' and PR.SupplierId=' + @SupplierId
		
		if (@ChainId<>'-1')						
			set @sqlReport4 = @sqlReport4 + ' and PR.ChainID=' + @ChainId
		
		exec ( @sqlReport4 )
	End
	
	if (@ReportType='5')
	Begin
		set @sqlReport5  = 'select distinct f.Banner, f.[Product Code] as UPC, F.Description as [Item Description],
					  cast(PR.UnitPrice as numeric(10,2)) as [IC Cost], 
					  cast(F.[Base Cost] as numeric(10,2)) as [Retailer Cost],
					  cast(PR.Allowance as numeric(10,2)) as [IC Allowance], 
					  cast(F.Allowance as numeric(10,2)) as [Retailer Allowance], 
					  (cast(PR.UnitPrice as numeric(10,2)) - cast(PR.Allowance as numeric(10,2))) as [IC Net], 
					  (cast(F.[Base Cost] as numeric(10,2)) - cast(F.Allowance as numeric(10,2)))  as [Retailer Net],
					  convert(varchar(10), PR.ActiveStartDate, 101) as [IC Start Date],
					  convert(varchar(10), F.[Cost Effective Date] , 101) as [Retailer Start Date],
					  convert(varchar(10), PR.ActiveLastDate , 101) as [IC End Date],
					  convert(varchar(10), F.[Cost End Date] , 101) as [Retailer End Date],
					  ''Cost Dates Mismatch''  as [Change Type]
					from ' + @TableName + ' f  
					
					inner Join  ProductIdentifiers p on CAST(p.IdentifierValue as varchar) =  CAST(F.[Product Code] as varchar)
					inner join ProductPrices PR on PR.ProductID=P.ProductID 
					inner join Stores S on S.StoreId=PR.StoreId and S.Custom1=f.Banner
					where PR.ProductPriceTypeID=3  and P.ProductIdentifierTypeID=2
					and (cast(PR.UnitPrice as numeric(10,2)) - cast(F.[Base Cost] as numeric(10,2))) = 0 
					and convert(varchar(10), PR.ActiveStartDate , 101)<> convert(varchar(10), F.[Cost Effective Date] , 101)'
					
		if (@SupplierId<>'-1')						
			set @sqlReport5 = @sqlReport5 + ' and PR.SupplierId=' + @SupplierId
		
		if (@ChainId<>'-1')						
			set @sqlReport5 = @sqlReport5 + ' and PR.ChainID=' + @ChainId
			
		exec ( @sqlReport5 )
		
	End
	if (@ReportType='6')
	Begin
		set @sqlReport6  = 'select distinct f.Banner, f.[Product Code] as UPC, F.Description as [Item Description],
					  cast(PR.UnitPrice as numeric(10,2)) as [IC Cost], 
					  cast(F.[Base Cost] as numeric(10,2)) as [Retailer Cost],
					  cast(PR.Allowance as numeric(10,2)) as [IC Allowance], 
					  cast(F.Allowance as numeric(10,2)) as [Retailer Allowance], 
					  (cast(PR.UnitPrice as numeric(10,2)) - cast(PR.Allowance as numeric(10,2))) as [IC Net], 
					  (cast(F.[Base Cost] as numeric(10,2)) - cast(F.Allowance as numeric(10,2)))  as [Retailer Net],
					  convert(varchar(10), PR.ActiveStartDate, 101) as [IC Start Date],
					  convert(varchar(10), F.[Cost Effective Date] , 101) as [Retailer Start Date],
					  convert(varchar(10), PR.ActiveLastDate , 101) as [IC End Date],
					  convert(varchar(10), F.[Cost End Date] , 101) as [Retailer End Date],
					  ''Promo Dates Mismatch'' as [Change Type]
					from ' + @TableName + ' f  
					
					inner Join ProductIdentifiers p on CAST(p.IdentifierValue as varchar) =  CAST(F.[Product Code] as varchar)
					inner join ProductPrices PR on PR.ProductID=P.ProductID 
					inner join Stores S on S.StoreId=PR.StoreId and S.Custom1=f.Banner
					where P.ProductIdentifierTypeID=2 and PR.ProductPriceTypeID=8 
					and (cast(isnull(PR.UnitPrice,0) as numeric(10,2)) = cast(isnull(F.[Base Cost],0) as numeric(10,2))) 
					and (cast(isnull(PR.Allowance,0) as numeric(10,2)) = cast(isnull(F.[Allowance],0) as numeric(10,2)))  
					and (convert(varchar(10), PR.ActiveStartDate , 101)<> convert(varchar(10), F.[Cost Effective Date] , 101)
					or   convert(varchar(10), PR.ActiveLastDate , 101)<> convert(varchar(10), F.[Cost End Date] , 101))'
					
		if (@SupplierId<>'-1')						
			set @sqlReport6 = @sqlReport6 + ' and PR.SupplierId=' + @SupplierId
		
		if (@ChainId<>'-1')						
			set @sqlReport6 = @sqlReport6 + ' and PR.ChainID=' + @ChainId
			
		exec ( @sqlReport6 )
	End
	
End
GO
