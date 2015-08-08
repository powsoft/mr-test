USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_InvoicesInvalid]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_InvoicesInvalid]
 @ChainId varchar(50),
 @SupplierId varchar(50),
 @RetailerConfirmationTypeID varchar(50),
 @InvoiceNo varchar(100),
 @EffectiveDateFrom varchar(50),
 @EffectiveDateTo varchar(50),
 @Status varchar(50)
as
-- exec [usp_InvoicesInvalid] '50964','50731','','','1900-01-01','1900-01-01','-1'
Begin
 Declare @sqlQuery varchar(4000)
 
 SET @sqlQuery ='Select C.ChainName,
						S.SupplierName,
						IT.InvalidInvoiceTypeDesc as [Invoice Type Desc],
						I.InvoiceNo,
						Convert(Varchar(12),I.EffectiveDate,101) AS EffectiveDate,
						convert(varchar(12),p.TermsNetDueDate,101) AS [Due Date],
						I.TotalAmt,
						--CASE I.RecordStatus WHEN 0 THEN ''Pending'' WHEN 1 THEN ''Approved'' WHEN 3 THEN 
						''Rejected''  as [RecordStatus],
						i.FileName
							
					FROM dbo.ACH_InvalidInvoices I With(NOLOCK)
						INNER JOIN dbo.ACH_invalidinvoicetypes IT With(NOLOCK) ON I.InvalidInvoiceType=IT.InvalidInvoiceTypeID
						INNER JOIN dbo.Chains C With(NOLOCK) ON C.ChainID=I.ChainID
						INNER JOIN dbo.Suppliers S With(NOLOCK) ON S.SupplierID=I.SupplierID
						INNER JOIN (
										Select distinct ReferenceIdentification, 
														TermsNetDueDate,
														Chainname As ChainIdentifier,
														SupplierIdentifier,FileName
										from DataTrue_Edi.dbo.Inbound846Inventory_ACH
								   ) AS P ON P.ReferenceIdentification=I.InvoiceNo 
											AND P.ChainIdentifier=C.ChainIdentifier
											AND P.SupplierIdentifier=S.EDIName and i.filename=p.filename
						
					WHERE Actionable = 0 '

	IF(@ChainId <>'-1')		
		set @sqlQuery  = @sqlQuery  + ' AND C.ChainID =' + @ChainId

	IF(@SupplierId <>'-1')
		set @sqlQuery  = @sqlQuery  + ' AND S.SupplierID =' + @SupplierId
		
	IF(@InvoiceNo <>'')
		set @sqlQuery  = @sqlQuery  + ' AND I.InvoiceNo =''' + @InvoiceNo + ''''
		
	IF(convert(date, @EffectiveDateFrom ) > convert(date,'1900-01-01'))
		set @sqlQuery = @sqlQuery + ' AND I.EffectiveDate>= ''' + @EffectiveDateFrom + ''''

	IF(convert(date, @EffectiveDateTo ) > convert(date,'1900-01-01'))
		set @sqlQuery = @sqlQuery + ' AND I.EffectiveDate <= ''' + @EffectiveDateTo + ''''
	
	if(@Status='0')--Pending
		set @sqlQuery = @sqlQuery + ' and I.RecordStatus=99  ' 
	else if(@Status='1')	--Approved
		set @sqlQuery = @sqlQuery + ' and I.RecordStatus=99 ' 
	else if(@Status='3')	--Rejected
		set @sqlQuery = @sqlQuery + ' and I.RecordStatus in (0,1,3) ' 

	print(@sqlQuery);
	EXEC(@sqlQuery);

End
GO
