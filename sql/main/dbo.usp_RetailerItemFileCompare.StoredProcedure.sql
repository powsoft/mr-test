USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_RetailerItemFileCompare]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:  <Author,,Name>
-- Create date: <Create Date,,>
-- Description: <Description,,>
-- =============================================
--usp_RetailerItemFileCompare '40393','-1','','-1','','1/1/1900','1/1/1900',8,0
CREATE PROCEDURE [dbo].[usp_RetailerItemFileCompare]

 @AttributeValue varchar(10),
 @supplierID varchar(10),
 @Product varchar(20),
 @Banner varchar(255),
 @UPC varchar(100),
 @BeginDate varchar(50),
 @EndDate varchar(50),
 @RequestType varchar(50),
 @ReportType varchar(50)
AS
BEGIN
Declare @sqlQuery varchar(6000)

 set @sqlQuery ='SELECT convert(varchar(10), dbo.RetailerItemFileCompare.RequestDate,101) as [Request Date], dbo.Suppliers.SupplierName as Supplier, dbo.Products.ProductName as Product, 
                      dbo.RetailerItemFileCompare.UPC, case dbo.RetailerItemFileCompare.Type when 3 then ''Cost'' when 8 then ''Promotion'' end as [Cost/Promo],
                      case dbo.RetailerItemFileCompare.ReportType when 1 then ''Cost Mismatch'' when 2 then '' Cost Not In iControl Records'' when 3 then ''Cost Not In Retailer Records'' when 4 then ''Dates mistmatch'' end as [Mismatch Type],
                      
                        convert(varchar(12),dbo.RetailerItemFileCompare.BeginDate,101) as [Retailer-Begin], convert(varchar(12),dbo.RetailerItemFileCompare.EndDate, 101)  as [Retailer-End], SystemBeginDate as [iControl-Begin],SystemEndDate as [iControl-End],
                      dbo.RetailerItemFileCompare.Banner, dbo.RetailerItemFileCompare.Unitprice as [iControl Cost], dbo.RetailerItemFileCompare.ReportedPrice as [Retailer Cost], 
                      dbo.RetailerItemFileCompare.Filename
				FROM dbo.RetailerItemFileCompare INNER JOIN
                      dbo.Products ON dbo.RetailerItemFileCompare.ProductID = dbo.Products.ProductID 
                      INNER JOIN dbo.Suppliers ON dbo.RetailerItemFileCompare.SupplierID = dbo.Suppliers.SupplierID 
                      inner join SupplierBanners SB on SB.SupplierId = dbo.RetailerItemFileCompare.SupplierId and SB.Status=''Active'' and SB.Banner=dbo.RetailerItemFileCompare.Custom1
                      where dbo.RetailerItemFileCompare.ChainID  = ' + @AttributeValue

	if(@supplierID <>'-1') 
		set @sqlQuery = @sqlQuery +  ' and dbo.RetailerItemFileCompare.supplierid=' + @supplierID  

	else if(@Banner <>'-1') 
		set @sqlQuery = @sqlQuery + ' and  dbo.RetailerItemFileCompare.Banner=''' + @Banner   + ''''

	if( convert(date, @BeginDate  ) > convert(date,'1900-01-01') and  convert(date, @EndDate ) > convert(date,'1900-01-01') ) 
		set @sqlQuery = @sqlQuery + ' and  dbo.RetailerItemFileCompare.RequestDate  >= ''' + @BeginDate   + ''' and dbo.RetailerItemFileCompare.RequestDate  <= ''' + @EndDate  + ''''  ;

	else if (convert(date, @BeginDate   ) > convert(date,'1900-01-01'))
		set @sqlQuery = @sqlQuery + ' and  dbo.RetailerItemFileCompare.RequestDate  >= ''' + @BeginDate   + '''';

	else if(convert(date, @EndDate  ) > convert(date,'1900-01-01')) 
		set @sqlQuery = @sqlQuery + ' and dbo.RetailerItemFileCompare.RequestDate  <= ''' + @EndDate   + '''';


	if(@UPC<>'') 
		set @sqlQuery = @sqlQuery + ' and dbo.RetailerItemFileCompare.UPC like ''%' + @UPC + '%''';
		
	if(@Product <>'') 
		set @sqlQuery = @sqlQuery + ' and dbo.Products.ProductName like ''%' + @Product  + '%''';

	if(@ReportType>0) 
		set @sqlQuery = @sqlQuery + ' and dbo.RetailerItemFileCompare.ReportType = ' +  @ReportType 
		
	if(@RequestType >0) 
		set @sqlQuery = @sqlQuery + ' and dbo.RetailerItemFileCompare.Type= ' +  @RequestType 
		
	exec (@sqlQuery  )

END
GO
