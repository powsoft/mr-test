USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_InsertIntoTempTable]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[amb_InsertIntoTempTable]  
@filePath nvarchar(200)
as 
Begin
	declare @datasource varchar(500)
	declare @sqlQuery varchar(2000)
	
	set @datasource =  'Excel 12.0;Database=' + @filepath + ';HDR=YES'
	
	--drop table #FileComparisonTool
	set @sqlQuery  = ' select * into #FileComparisonTool FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'','''+ @datasource + ''' , ''SELECT * FROM [sheet1$]''); 

	select f.Banner, f.[Product Code] as UPC, F.Description, PR.UnitPrice as ICCost, 
	F.[Base Cost] as FCost, PR.Allowance as ICPromo, F.Allowance as FPromo, case when pr.UnitPrice-f.[Base Cost] = 0  then '''' else ''Base Cost Change'' end as TypeOfChange
	from #FileComparisonTool f  
	inner Join  ProductIdentifiers p on CAST(p.IdentifierValue as varchar) =  CAST(F.[Product Code] as varchar)
	left join ProductPrices PR on PR.ProductID=P.ProductID 
	where F.Allowance=0 and PR.ProductPriceTypeID=3 and PR.ActiveStartDate=F.[Cost Effective Date] and pr.UnitPrice-f.[Base Cost] <>0 
	Union ALL

	select f.Banner, f.[Product Code] as UPC, F.Description, PR.UnitPrice as ICCost, 
	F.[Base Cost] as FCost, PR.Allowance as ICPromo, F.Allowance as FPromo,case when pr.Allowance -f.allowance = 0 then '''' else ''Promo Change'' end as TypeOfChange
	from #FileComparisonTool f  
	inner Join  ProductIdentifiers p on CAST(p.IdentifierValue as varchar) =  CAST(F.[Product Code] as varchar)
	left join ProductPrices PR on PR.ProductID=P.ProductID 
	where F.Allowance>0 and PR.ProductPriceTypeID=8 and PR.ActiveStartDate=F.[Cost Effective Date] 
	and PR.ActiveLastDate=F.[Cost End Date] and pr.Allowance -f.allowance <> 0 ;'
	
	exec ( @sqlQuery )

End
GO
