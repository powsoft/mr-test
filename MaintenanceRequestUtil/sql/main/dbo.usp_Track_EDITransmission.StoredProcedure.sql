USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Track_EDITransmission]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_Track_EDITransmission] 
 @ChainID varchar(5),
 @SupplierId varchar(5),
 @Custom1 varchar(255),
 @SubmissionDateFrom varchar(50),
 @SubmissionDateTo varchar(50),
 @TransmissionDateFrom varchar(50),
 @TransmissionDateTo varchar(50),
 @ProductIdentifierType int,
 @ProductIdentifierValue varchar(50),
 @RequestType varchar(10)
 
 as
 -- exec usp_Track_EDITransmission '40393','-1','-1','1900-01-01','1900-01-01','1900-01-01','1900-01-01','2','','4'
 begin 
declare @strSQLCost varchar(4000)
declare @strSQLPromo varchar(4000)
declare @strSQL varchar(4000)

		set @strSQLCost = ' Select CN.ChainName as [Chain Name], C.PartnerName as [Supplier Name], 
						C.dtbanner as Banner, C.ProductName as [Product Name], C.ProductIdentifier as UPC,
						case when C.RequestTypeID=1 then ''New Item'' else ''Cost Change'' 
						end as [Request Type],
						convert(varchar,C.SubmitDateTime,101) as [Submission Date], 
						convert(varchar,C.datesenttoretailer,101) as [Transmission Date], 
						C.Cost as [Base Cost], 
						Null as Allowance, 
						convert(varchar,C.EffectiveDate ,101) as [Start Date],
						convert(varchar,C.EndDate ,101) as [End Date], C.FileName as [File Name]
						from DataTrue_EDI.dbo.Costs C 
						inner join Chains CN on CN.ChainId=C.dtchainid
						where C.Senttoretailer =1 '

			if(@SupplierId <>'-1')
            set @strSQLCost = @strSQLCost +  ' and C.dtSupplierId=' + @SupplierId

      if(@ChainID <>'-1')
            set @strSQLCost = @strSQLCost +  ' and C.dtchainid=' + @ChainID

      if(@custom1<>'-1')
            set @strSQLCost = @strSQLCost + ' and C.dtbanner=''' + @Custom1 + ''''
         
			if(convert(date,@SubmissionDateFrom) > convert(date,'1900-01-01'))
			set @strSQLCost = @strSQLCost + ' and C.SubmitDateTime  >= ''' + @SubmissionDateFrom + '''';
			
		 if(convert(date,@SubmissionDateTo) > convert(date,'1900-01-01'))
			set @strSQLCost = @strSQLCost + ' and C.SubmitDateTime <= ''' + @SubmissionDateTo + '''';
			
			if(convert(date,@TransmissionDateFrom) >convert(date,'1900-01-01')) 
			set @strSQLCost = @strSQLCost + ' and C.datesenttoretailer  >= ''' + @TransmissionDateFrom + '''';
			
			if(convert(date,@TransmissionDateTo) >convert(date,'1900-01-01'))
			set @strSQLCost = @strSQLCost + ' and C.datesenttoretailer  <= ''' + @TransmissionDateTo + '''';
	
         if(@ProductIdentifierValue<>'')
		 begin
			-- 2 = UPC, 3 = Product Name 
			if (@ProductIdentifierType=2)
				set @strSQLCost = @strSQLCost + ' and C.ProductIdentifier like ''%' + @ProductIdentifierValue + '%'''
			         
			else if (@ProductIdentifierType=3)
				set @strSQLCost = @strSQLCost + ' and C.ProductName like ''%' + @ProductIdentifierValue + '%'''	
		 end
	           
		set @strSQLPromo = ' Select CN.ChainName as [Chain Name], S.SupplierName as [Supplier Name], 
							P.dtbanner as Banner, P.ProductName as [Product Name], P.ProductIdentifier as UPC,
							''Promo'' as [Request Type],
							convert(varchar,P.SubmitDateTime,101) as [Submission Date], 
							convert(varchar,P.datesenttoretailer, 101) as [Transmission Date], 
							P.Cost as [Base Cost],
							P.Allowance_ChargeRate as Allowance, 
							convert(varchar,P.DateStartPromotion, 101) as [Start Date], convert(varchar,
							P.DateEndPromotion ,101) as [End Date], P.FileName as [File Name]
							from DataTrue_EDI.dbo.Promotions P
							inner join Chains CN on CN.ChainId=P.ChainId
							inner join Suppliers S on S.SupplierId=P.SupplierId
							where P.SentToRetailer =1 '

		if(@SupplierId <>'-1')
            set @strSQLPromo = @strSQLPromo +  ' and P.SupplierId=' + @SupplierId

        if(@ChainID <>'-1')
            set @strSQLPromo = @strSQLPromo +  ' and P.ChainId=' + @ChainID

        if(@custom1<>'-1')
            set @strSQLPromo = @strSQLPromo + ' and P.dtbanner=''' + @Custom1 + ''''
            
     	if(convert(date,@SubmissionDateFrom) > convert(date,'1900-01-01'))
			set @strSQLPromo = @strSQLPromo + ' and P.SubmitDateTime  >= ''' + @SubmissionDateFrom + '''';
			
		 if(convert(date,@SubmissionDateTo) > convert(date,'1900-01-01') )
			set @strSQLPromo = @strSQLPromo + ' and P.SubmitDateTime  <= ''' + @SubmissionDateTo + '''';  
			
			if(convert(date,@TransmissionDateFrom) >convert(date,'1900-01-01')) 
			set @strSQLPromo = @strSQLPromo + ' and P.datesenttoretailer  >= ''' + @TransmissionDateFrom + '''';
			
			if(convert(date,@TransmissionDateTo) >convert(date,'1900-01-01'))
			set @strSQLPromo = @strSQLPromo + ' and P.datesenttoretailer  <= ''' + @TransmissionDateTo + ''''; 
         
         if(@ProductIdentifierValue<>'')
		 begin
			-- 2 = UPC, 3 = Product Name 
			if (@ProductIdentifierType=2)
				set @strSQLPromo = @strSQLPromo + ' and P.ProductIdentifier like ''%' + @ProductIdentifierValue + '%'''	         
			else if (@ProductIdentifierType=3)
				set @strSQLPromo = @strSQLPromo + ' and P.ProductName like ''%' + @ProductIdentifierValue + '%'''	
		 end

		if(@RequestType<3)
			set @strSQL = @strSQLCost + ' and C.RequestTypeID=' + @RequestType
		else if(@RequestType=3)	
			set @strSQL = @strSQLPromo 
		else if(@RequestType=4)		
			set @strSQL = @strSQLCost + ' union all ' + @strSQLPromo 
	
	print(@strSQL);
	Exec (@strSQL);
	
end
GO
