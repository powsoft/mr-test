USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_Track_EDITransmission_All]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- alter  date: <alter  Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE  procedure [dbo].[usp_Report_Track_EDITransmission_All] 
	-- exec usp_Report_Track_EDITransmission_All '40393','40384','All','','-1','','0','2013-01-01','2013-12-31'
	@chainID varchar(max),
	@PersonID int,
	@Banner varchar(50),
	@ProductUPC varchar(20),
	@SupplierId varchar(max),
	@StoreId varchar(10),
	@LastxDays int,
	@StartDate varchar(20),
	@EndDate varchar(20)
AS
BEGIN

declare @strSQLCost varchar(max)
declare @strSQLPromo varchar(max)
declare @strSQL varchar(max)

		set @strSQLCost = ' Select CN.ChainName as [Chain Name], C.PartnerName as [Supplier Name], 
						C.dtbanner as Banner, C.ProductName as [Product Name], C.ProductIdentifier as UPC,
						case when C.RequestTypeID=1 then ''New Item'' else ''Cost Change'' 
						end as [Request Type],
						convert(varchar(10),C.SubmitDateTime,101) as [Submission Date], 
						convert(varchar(10),C.datesenttoretailer,101) as [Transmission Date], 
						''$''+ Convert(varchar(50), C.Cost) as [Base Cost], 
						''$''+ Convert(varchar(50), Null) as Allowance, 
						convert(varchar(10),C.EffectiveDate ,101) as [Start Date],
						convert(varchar(10),C.EndDate ,101) as [End Date], C.FileName as [File Name]
						from Costs C  WITH(NOLOCK) 
						inner join Chains CN WITH(NOLOCK)  on CN.ChainId=C.dtchainid
						where C.Senttoretailer =1 '

			if(@SupplierId <>'-1')
				set @strSQLCost = @strSQLCost +  ' and C.dtSupplierId in (' + @SupplierId+')'

			if(@ChainId <>'-1')
				set @strSQLCost = @strSQLCost +  ' and C.dtchainid in(' + @ChainId +')'

			if(@Banner<>'All')
				set @strSQLCost = @strSQLCost + ' and C.dtbanner=''' + @Banner + ''''
	
			if(convert(date,@StartDate) > convert(date,'1900-01-01'))
				set @strSQLCost = @strSQLCost + ' and C.datesenttoretailer  >= ''' + @StartDate + '''';

			if(convert(date,@EndDate) > convert(date,'1900-01-01'))
				set @strSQLCost = @strSQLCost + ' and C.datesenttoretailer <= ''' + @EndDate + '''';

			if(@ProductUPC<>'-1')
				set @strSQLCost = @strSQLCost + ' and C.ProductIdentifier like ''%' + @ProductUPC + '%'''
	
			if (@LastxDays > 0)
				set @strSQLCost = @strSQLCost + ' and (C.datesenttoretailer between dateadd(d,-' +  
							 cast(@LastxDays as varchar) + ', { fn NOW() }) and { fn NOW() })'
			
	           
		set @strSQLPromo = ' Select CN.ChainName as [Chain Name], S.SupplierName as [Supplier Name], 
							P.dtbanner as Banner, P.ProductName as [Product Name], P.ProductIdentifier as UPC,
							''Promo'' as [Request Type],
							convert(varchar(10),P.SubmitDateTime,101) as [Submission Date], 
							convert(varchar(10),P.datesenttoretailer, 101) as [Transmission Date], 
							''$''+ Convert(varchar(50), P.Cost) as [Base Cost],
							''$''+ Convert(varchar(50), P.Allowance_ChargeRate) as Allowance, 
							convert(varchar(10),P.DateStartPromotion, 101) as [Start Date], 
							convert(varchar(10),P.DateEndPromotion ,101) as [End Date], P.FileName as [File Name]
							from Promotions P WITH(NOLOCK) 
							inner join Chains CN WITH(NOLOCK)  on CN.ChainId=P.ChainId
							inner join Suppliers S WITH(NOLOCK)  on S.SupplierId=P.SupplierId
							where P.SentToRetailer =1 '

		if(@SupplierId <>'-1')
            set @strSQLPromo = @strSQLPromo +  ' and P.SupplierId in (' + @SupplierId +')'

        if(@ChainId <>'-1')
            set @strSQLPromo = @strSQLPromo +  ' and P.ChainId in (' + @ChainId +')'

       if(@Banner<>'All')
            set @strSQLPromo = @strSQLPromo + ' and P.dtbanner=''' + @Banner + ''''
            
     	if(convert(date,@StartDate) > convert(date,'1900-01-01'))
			set @strSQLPromo = @strSQLPromo + ' and P.datesenttoretailer  >= ''' + @StartDate + '''';
			
		 if(convert(date,@EndDate) > convert(date,'1900-01-01') )
			set @strSQLPromo = @strSQLPromo + ' and P.datesenttoretailer  <= ''' + @EndDate + '''';  
			
         if(@ProductUPC<>'-1')
			set @strSQLPromo = @strSQLPromo + ' and P.ProductIdentifier like ''%' + @ProductUPC + '%'''	 
				
		if (@LastxDays > 0)
			set @strSQLPromo = @strSQLPromo + ' and (P.datesenttoretailer between dateadd(d,-' +  
							 cast(@LastxDays as varchar) + ', { fn NOW() }) and { fn NOW() })'	        
	
			set @strSQL = @strSQLCost + ' union all ' + @strSQLPromo 
	
	exec (@strSQL)
END
GO
