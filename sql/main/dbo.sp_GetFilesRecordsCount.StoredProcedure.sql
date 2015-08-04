USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[sp_GetFilesRecordsCount]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  Procedure [dbo].[sp_GetFilesRecordsCount]     
     @FileName  nvarchar(100)    
    
AS    
    
    
--select distinct FileName     
--from DAtatrue_EDI..Inbound846Inventory    
--where -- WorkingStatus=-1313 and    
--PurposeCode in ('DB','CR')    
--and CAST(EffectiveDate   as date)='2013-03-26'    
--and EdiName  = 'PEP'
    
BEGIN    
    SET NOCOUNT ON;    
        
    declare @RecordCount1 nvarchar(10)    
    declare @RecordCount2 nvarchar(10)    
    declare @RecordCount3 nvarchar(10)    
    
    
select @RecordCount1 = COUNT(*)    
from DataTrue_EDI..Inbound846Inventory    
where -- WorkingStatus=-1313 and    
1=1     
and PurposeCode in ('CR','DB') ANd RecordStatus  = 1    
and FileName = @FileName     
    
    
    
select @RecordCount2 = COUNT(*)    
from StoreTransactions_Working    
where -- WorkingStatus=-1313 and    
1=1     
and WorkingSource in ('SUP-U','SUP-S')    
and SourceIdentifier = @FileName     
    
select @RecordCount3 = COUNT(*)    
from DataTrue_Archive..StoreTransactions_Working    
where -- WorkingStatus=-1313 and    
1=1     
and WorkingSource in ('SUP-U','SUP-S')    
and SourceIdentifier = @FileName     
    
select 'FileName'= @FileName ,'EDICount' = @RecordCount1, 'MainCount' = @RecordCount2,'ArchiveCount' = @RecordCount3    
    
End
GO
