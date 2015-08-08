USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_UpdateInvalidInvoies]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- [usp_UpdateInvalidInvoies] 'Inbound846Inventory_ACH','Qty','3','','','SPN','WOOD' ,'82762','20141124_10734_000065138_000073521_iControl.TXT','11/12/2014',1438924

CREATE PROC [dbo].[usp_UpdateInvalidInvoies]
@TableName VARCHAR(100),
@FieldName VARCHAR(100),
@FieldValue VARCHAR(100),
@TranslationFieldName VARCHAR(100),
@TranslationFieldValue VARCHAR(100),
@ChainIdentifier VARCHAR(50),
@SupplierIdentifier VARCHAR(50),
@InvoiceNo VARCHAR(50),
@FileName VARCHAR(120),
@EffectiveDate VARCHAR(20),
@RecordID Int

AS 

BEGIN
	/*** Update Table Data ***/
		
	DECLARE @Query  VARCHAR(1000)
	
	IF(@RecordID = 0)
		BEGIN
			SET @Query = 'UPDATE [DataTrue_EDI].[dbo].['+@TableName+']
							SET [' + @FieldName + '] = ''' + @FieldValue + ''',
							[TimeStamp] = GetDate()
				            --   select * from    [DataTrue_EDI].[dbo].['+@TableName+']                         
							WHERE [ChainName] = ''' + @ChainIdentifier + ''' 
								AND [SupplierIdentifier] =  ''' + @SupplierIdentifier +'''
								AND [ReferenceIdentification] =''' +  @InvoiceNo +'''
								AND [FileName] =''' +  @FileName + '''
								AND [EffectiveDate] IN (
															SELECT Distinct EffectiveDate AS EffectiveDate  
															FROM [DataTrue_EDI].[dbo].[Inbound846Inventory_ACH]  
															Where ReferenceIDentification='''+ @InvoiceNo + ''' 
															and Chainname='''+@ChainIdentifier + ''' 
															and SupplierIdentifier='''+@SupplierIdentifier + '''
															and [FileName]='''+ @FileName +'''
														)
								AND [RecordStatus]=255'
		END
	ELSE
		BEGIN
			SET @Query = 'UPDATE [DataTrue_EDI].[dbo].['+@TableName+']
						     SET  '
			
			if(len(ltrim(rtrim(@TranslationFieldName))) > 1)
						SET @Query += '	[' + @TranslationFieldName + '] = ''' + @TranslationFieldValue + ''','
		
			SET @Query += '	[' + @FieldName + '] = ''' + @FieldValue + ''', 
								[TimeStamp] = GetDate()
				                                           
							WHERE [RecordID] = '+ cast(@RecordID  as varchar(12))
		END
	PRINT (@Query)
	EXEC (@Query)

END
GO
