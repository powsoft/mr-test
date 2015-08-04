USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Report_SupplierActionable_Pending_All]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- alter  date: <alter  Date,,>
-- Description:	<Description,,>
-- =============================================
-- exec [usp_Report_SupplierActionable_Pending_All] '79370','41713','All','','81523,79651,91706,81610,81926,91650,80701,82101,82519,81728,80259,82134,94550,80666,81658,81640,80697,79878,81508,79412,82003,76237,81717,81928,82096,81635,82011,81803,81814,79610,83268,0,79944,79768,81756,81519,79765,81543,81642,74216,79641,83059,83264,81997,82547,81867,73564,81722,79892,82030,82143,79629,81780,79625,79772,83003,79623,82086,80340,81887,78454,79953,82575,81747,81817,94083,82042,94944,82013,80646,81923,82093,91579,91816,95376,75150,79632,80506,79898,80257,82032,76209,81908,81686,82082,91811,79616,81536,82512,81753,82580,91839,79203,79612,81750,81681,81652,74767,79839,82641,80492','','-1','1900-01-01','1900-01-01'
CREATE procedure [dbo].[usp_Report_SupplierActionable_Pending_All] 
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
 
	set @query = ' Select Distinct  C.ChainName,    
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


		IF @AttValue =17
			SET @Query = @Query + ' AND C.ChainID in (select attributepart from dbo.fnGetRetailersTable(' +  cast(@PersonID as varchar) + '))'
		ELSE
			SET @Query = @Query + ' AND S.SupplierID in (select attributepart from dbo.fnGetSupplierTable(' +  cast(@PersonID as varchar) + '))'
			
		IF(@SupplierId<>'-1') 
			SET @Query  = @Query  + ' AND S.SupplierID in (' + @SupplierId  + ')'

		IF(@chainID  <>'-1') 
			SET @Query  = @Query  +  ' AND C.ChainID in (' + @chainID + ')'

		--if(@Banner<>'All') 
		--	set @Query  = @Query + ' and Stores.Custom1 like ''%' + @Banner + '%'''

		--if(@StoreId <>'-1') 
		--	set @Query   = @Query  +  ' and Stores.StoreIdentifier like ''%' + @StoreId + '%'''

		--if(@ProductUPC  <>'-1') 
		--	set @Query   = @Query  +  ' and ProductIdentifiers.IdentifierValue like ''%' + @ProductUPC + '%'''

		--if (@LastxDays > 0)
		--	set @Query = @Query + ' and (I.EffectiveDate >=dateadd(d,-' +  cast(@LastxDays as varchar) + ',getdate()) and RC.EffectiveDate <=getdate()) '  
		
		IF (convert(date, @StartDate  ) > convert(date,'1900-01-01'))
			SET @Query = @Query + ' and I.EffectiveDate >= ''' + @StartDate  + '''';

		IF(convert(date, @EndDate ) > convert(date,'1900-01-01')) 
			SET @Query = @Query + ' and I.EffectiveDate <= ''' + @EndDate  + '''';
		
		EXEC  (@Query )
		PRINT  (@Query )
END
GO
