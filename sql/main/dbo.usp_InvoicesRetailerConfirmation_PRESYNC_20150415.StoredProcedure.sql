USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_InvoicesRetailerConfirmation_PRESYNC_20150415]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_InvoicesRetailerConfirmation_PRESYNC_20150415]
 @ChainId varchar(50),
 @SupplierId varchar(50),
 @RetailerConfirmationTypeID varchar(50),
 @InvoiceNo varchar(100),
 @EffectiveDateFrom varchar(50),
 @EffectiveDateTo varchar(50),
 @Status varchar(50)
as
-- exec [usp_InvoicesRetailerConfirmation] '50964','-1','-1','','1/1/1900','1/1/1900',-1
Begin
 Declare @sqlQuery varchar(4000)
 
 set @sqlQuery = 'Select RC.ConfirmationID, 
							C.ChainName,
							S.SupplierName,
							RCT.ConfirmationTypeDesc,
							RC.InvoiceNo,
							Convert(varchar,RC.EffectiveDate,101) as EffectiveDate,
							RC.TotalAmt,
							Convert(varchar,RC.RequestDate,101) as RequestDate,
							Convert(varchar,RC.ConfirmationDate,101) as ConfirmationDate,
							RC.ConfirmationReceived,
							CASE WHEN (RC.RecordStatus=0 and RC.ConfirmationReceived=0 and RC.RequestSent=1) 
								 THEN ''Pending'' 
								 WHEN (RC.RecordStatus=0 and RC.ConfirmationReceived=1) THEN ''Approved''
								 WHEN (RC.RecordStatus=3)
								 THEN ''Rejected''
						    End AS [RecordStatus],
							C.ChainId,
							S.SupplierID
										
					FROM 
						dbo.ACH_RetailerConfirmations RC with(nolock) 
						INNER JOIN dbo.ACH_RetailerConfirmationTypes RCT with(nolock) ON RC.ConfirmationType=RCT.ConfirmationTypeID
						INNER JOIN dbo.Chains C with(nolock) ON C.ChainID=RC.ChainID
						INNER JOIN dbo.Suppliers S with(nolock) ON S.SupplierID=RC.SupplierID
					
					WHERE 1=1  '

	if(@ChainId <>'-1')
		set @sqlQuery  = @sqlQuery  + ' and C.ChainId =' + @ChainId

	if(@SupplierId <>'-1')
		set @sqlQuery  = @sqlQuery  + ' and S.SupplierID =' + @SupplierId

	if(@RetailerConfirmationTypeID <>'-1')
		set @sqlQuery  = @sqlQuery  + ' and RCT.ConfirmationTypeID =' + @RetailerConfirmationTypeID
		
	if(@InvoiceNo <>'')
		set @sqlQuery  = @sqlQuery  + ' and RC.InvoiceNo =''' + @InvoiceNo + ''''
		
	if (convert(date, @EffectiveDateFrom ) > convert(date,'1900-01-01'))
		set @sqlQuery = @sqlQuery + ' and RC.EffectiveDate>= ''' + @EffectiveDateFrom + ''''

	if(convert(date, @EffectiveDateTo ) > convert(date,'1900-01-01'))
		set @sqlQuery = @sqlQuery + ' and RC.EffectiveDate <= ''' + @EffectiveDateTo + ''''
    
	if(@Status='0')--Pending
		set @sqlQuery = @sqlQuery + ' and RC.RecordStatus=0 and RC.ConfirmationReceived=0 and RC.RequestSent=1 ' 
	else if(@Status='1')	--Approved
		set @sqlQuery = @sqlQuery + ' and RC.RecordStatus=0 and RC.ConfirmationReceived=1 ' 
	else if(@Status='3')	--Rejected
		set @sqlQuery = @sqlQuery + ' and RC.RecordStatus=3 ' 
		else 
		set @sqlQuery = @sqlQuery + ' and rc.recordstatus=0  and ConfirmationReceived =0 '
	 
	set @sqlQuery = @sqlQuery + ' order by C.ChainName,S.SupplierName,RCT.ConfirmationTypeDesc '
	
	print(@sqlQuery);
	exec(@sqlQuery);

End
GO
