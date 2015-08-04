USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_SupplierActionable_Pending]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- alter  date: <alter  Date,,>
-- Description:	<Description,,>
-- =============================================
--exec [usp_Report_SupplierActionable_Pending] '40393','41544','All','','-1','','5','1900-01-01','1900-01-01'
CREATE  procedure [dbo].[usp_Report_SupplierActionable_Pending] 
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
 
 SET @query = ' Select Distinct  C.ChainName,    
								  S.SupplierName, 
								  IT.InvalidInvoiceTypeDesc,    
								  I.InvoiceNo,    
								  convert(varchar,I.EffectiveDate,101) AS EffectiveDate,    
								  I.TotalAmt ,  
								  ''Pending'' AS [RecordStatus],
								  I.[FileName]
				
				 FROM     
					  dbo.ACH_InvalidInvoices I     
					  INNER JOIN dbo.ACH_invalidinvoicetypes IT ON I.InvalidInvoiceType=IT.InvalidInvoiceTypeID    
					  INNER JOIN dbo.Chains C ON C.ChainID=I.ChainID    
					  INNER JOIN dbo.Suppliers S ON S.SupplierID=I.SupplierID 
					  INNER JOIN (
									Select Distinct ReferenceIdentification, 
													TermsNetDueDate,
													Chainname As ChainIdentifier,
													SupplierIdentifier,
													RecordStatus,
													EffectiveDate,
													FileName
										from DataTrue_Edi.dbo.Inbound846Inventory_ACH  
									) AS P ON P.ReferenceIdentification=I.InvoiceNo 
												AND P.ChainIdentifier=C.ChainIdentifier
												AND P.SupplierIdentifier=S.EDIName
												AND P.FileName = I.FileName
   												AND P.EffectiveDate=I.EffectiveDate   
				
				WHERE    
					 1=1  and IT.Actionable=1 and I.RecordStatus=0 AND P.RecordStatus =255   '


		--if @AttValue =17
		--	set @Query = @Query + ' and c.ChainID in (select attributepart from dbo.fnGetRetailersTable(' +  cast(@PersonID as varchar) + '))'
		--else
		--	set @Query = @Query + ' and s.SupplierID in (select attributepart from dbo.fnGetSupplierTable(' +  cast(@PersonID as varchar) + '))'
		
		IF(@SupplierId<>'-1') 
			SET @Query  = @Query  + ' and S.SupplierID in (' + @SupplierId  + ')'

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
		
		IF (convert(date, @StartDate  ) > convert(date,'1900-01-01'))
			SET @Query = @Query + ' and I.EffectiveDate >= ''' + @StartDate  + '''';

		IF(convert(date, @EndDate ) > convert(date,'1900-01-01')) 
			SET @Query = @Query + ' and I.EffectiveDate <= ''' + @EndDate  + '''';
		
		EXEC(@Query)
END
GO
