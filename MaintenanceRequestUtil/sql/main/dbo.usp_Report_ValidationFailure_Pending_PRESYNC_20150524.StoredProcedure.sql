USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_ValidationFailure_Pending_PRESYNC_20150524]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- alter  date: <alter  Date,,>
-- Description:	<Description,,>
-- =============================================
--exec [usp_Report_ValidationFailure_Pending] '40393','41544','All','','-1','','5','1900-01-01','1900-01-01'
CREATE  procedure [dbo].[usp_Report_ValidationFailure_Pending_PRESYNC_20150524] 
	-- Add the parameters for the stored procedure here
	@chainID varchar(8000),
	@PersonID int,
	@Banner varchar(500),
	@ProductUPC varchar(20),
	@SupplierId varchar(8000),
	@StoreId varchar(10),
	@LastxDays int,
	@StartDate varchar(20),
	@EndDate varchar(20)
AS
BEGIN
Declare @Query varchar(5000)
declare @AttValue int

 select @attvalue = AttributeID  from AttributeValues WITH(NOLOCK)  where OwnerEntityID=@PersonID and AttributeID=17
 
	set @query = ' Select	C.ChainName,
							S.SupplierName,
							RCT.ConfirmationTypeDesc,
							RC.InvoiceNo,
							Convert(varchar,RC.EffectiveDate,101) as EffectiveDate,
							RC.TotalAmt,
							Convert(varchar,RC.RequestDate,101) as RequestDate
							,
							 ''Pending''					
						    AS [RecordStatus]
										
					FROM 
						dbo.ACH_RetailerConfirmations RC with(nolock) 
						INNER JOIN dbo.ACH_RetailerConfirmationTypes RCT with(nolock) ON RC.ConfirmationType=RCT.ConfirmationTypeID
						INNER JOIN dbo.Chains C with(nolock) ON C.ChainID=RC.ChainID
						INNER JOIN dbo.Suppliers S with(nolock) ON S.SupplierID=RC.SupplierID
					
					WHERE 1=1   and (RC.RecordStatus=0 and RC.ConfirmationReceived=0 and RC.RequestSent=1)  
 '


		--if @AttValue =17
		--	set @Query = @Query + ' and c.ChainID in (select attributepart from dbo.fnGetRetailersTable(' +  cast(@PersonID as varchar) + '))'
		--else
		--	set @Query = @Query + ' and s.SupplierID in (select attributepart from dbo.fnGetSupplierTable(' +  cast(@PersonID as varchar) + '))'
		if(@SupplierId<>'-1') 
			set @Query  = @Query  + ' and s.SupplierID in (' + @SupplierId  + ')'

		--if(@chainID  <>'-1') 
		--	set @Query   = @Query  +  ' and c.ChainID in (' + @chainID + ')'

		--if(@Banner<>'All') 
		--	set @Query  = @Query + ' and Stores.Custom1 like ''%' + @Banner + '%'''

		--if(@StoreId <>'-1') 
		--	set @Query   = @Query  +  ' and Stores.StoreIdentifier like ''%' + @StoreId + '%'''

		--if(@ProductUPC  <>'-1') 
		--	set @Query   = @Query  +  ' and ProductIdentifiers.IdentifierValue like ''%' + @ProductUPC + '%'''

		--if (@LastxDays > 0)
		--	set @Query = @Query + ' and (RC.EffectiveDate >=dateadd(d,-' +  cast(@LastxDays as varchar) + ',getdate()) and RC.EffectiveDate <=getdate()) '  
		
		if (convert(date, @StartDate  ) > convert(date,'1900-01-01'))
			set @Query = @Query + ' and RC.EffectiveDate >= ''' + @StartDate  + '''';

		if(convert(date, @EndDate ) > convert(date,'1900-01-01')) 
			set @Query = @Query + ' and RC.EffectiveDate <= ''' + @EndDate  + '''';
		print (@query)
		exec  (@Query )
END
GO
