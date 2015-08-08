USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_InvoicesParked]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_InvoicesParked]
 @ChainId varchar(50),
 @SupplierId varchar(50),
 @RetailerConfirmationTypeID varchar(50),
 @InvoiceNo varchar(100),
 @EffectiveDateFrom varchar(50),
 @EffectiveDateTo varchar(50),
 @Status varchar(50)
as
-- exec [usp_InvoicesParked] '50964','50731','-1','','1900-01-01','1900-01-01','-1'
Begin
 Declare @sqlQuery varchar(4000)
 
 SET @sqlQuery ='Select C.ChainName,
						S.SupplierName,
						IT.ParkedTypeDesc as [Invoice Type Desc],
						P.InvoiceNo,
						convert(varchar(12),P.EffectiveDate,101) AS EffectiveDate,
						convert(varchar(12),p1.TermsNetDueDate,101) AS [Due Date],
						P.TotalAmt,
						CASE P.RecordStatus WHEN 0 THEN ''Pending'' WHEN 1 THEN ''Approved'' WHEN 3 THEN ''Rejected'' End as [RecordStatus],
						case am.[IsAutoApprovalRegulated] when 1 then ''Auto Approve'' else ''Manual Approve'' end as ApproveType,
						p.FileName as [File Name],
						p2.StatusEDI,
						C.ChainID,
						S.SupplierID

					FROM dbo.ACH_ParkedInvoices P With(NOLOCK) 
						INNER JOIN dbo.ACH_ParkedInvoiceTypes IT With(NOLOCK) ON P.ParkedType=IT.ParkedTypeID
						INNER JOIN dbo.Chains C With(NOLOCK) ON C.ChainID=P.ChainID
						INNER JOIN dbo.Suppliers S With(NOLOCK) ON S.SupplierID=P.SupplierID	
						INNER JOIN (
										Select distinct ReferenceIdentification, 
														TermsNetDueDate,
														Chainname As ChainIdentifier,
														SupplierIdentifier,
														RecordStatus,
														EffectiveDate,
														FileName
										from DataTrue_Edi.dbo.Inbound846Inventory_ACH
								   ) AS P1 ON P1.ReferenceIdentification=P.InvoiceNo 
											AND P1.ChainIdentifier=C.ChainIdentifier
											AND P1.SupplierIdentifier=S.EDIname
											AND P1.EffectiveDate=P.EffectiveDate
											AND P1.FileName=P.FileName

						INNER JOIN (
										Select distinct ReferenceIdentification, 
														termsnetduedate,
														RecordStatus AS StatusEDI,
														Chainname As ChainIdentifier,
														SupplierIdentifier,
														RecordStatus,
														EffectiveDate,
														FileName
										from DataTrue_Edi.dbo.Inbound846Inventory_ACH_Approval
								   ) AS P2 ON P2.ReferenceIdentification=P.InvoiceNo 
											AND P2.ChainIdentifier=C.ChainIdentifier
											AND P2.SupplierIdentifier=S.supplieridentifier
											AND P2.EffectiveDate=P.EffectiveDate
											AND P2.FileName=P.FileName
											--and p2.RecordStatus in (5,6)
					inner join DataTrue_Main.dbo.ApprovalManagement am on am.chainid=p.chainid and am.supplierid=p.supplierid
					Where 1=1 '

	IF(@ChainId <>'-1')		
		set @sqlQuery  = @sqlQuery  + ' AND C.ChainID =' + @ChainId

	IF(@SupplierId <>'-1')
		set @sqlQuery  = @sqlQuery  + ' AND S.SupplierID =' + @SupplierId
		
	IF(@InvoiceNo <>'')
		set @sqlQuery  = @sqlQuery  + ' AND P.InvoiceNo =''' + @InvoiceNo + ''''
	
	--if(@Status='0')--Pending
		set @sqlQuery = @sqlQuery + ' and P.RecordStatus=0  ' 
	--else if(@Status='1')	--Approved
	--	set @sqlQuery = @sqlQuery + ' and P.RecordStatus=1 ' 
	--else if(@Status='3')	--Rejected
	--	set @sqlQuery = @sqlQuery + ' and P.RecordStatus=3 ' 

	IF(convert(date, @EffectiveDateFrom ) > convert(date,'1900-01-01'))
		set @sqlQuery = @sqlQuery + ' AND P.EffectiveDate>= ''' + @EffectiveDateFrom + ''''

	IF(convert(date, @EffectiveDateTo ) > convert(date,'1900-01-01'))
		set @sqlQuery = @sqlQuery + ' AND P.EffectiveDate <= ''' + @EffectiveDateTo + ''''
	
	print(@sqlQuery);
	EXEC(@sqlQuery);

End
GO
