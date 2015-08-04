USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[sp_Get_DBCR_FilesRecordsCount]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--sp_helptext sp_GetFilesRecordsCount
--exec [sp_Get_DBCR_FilesRecordsCount]  @FileName ='401300.MSG'     
      
CREATE  Procedure [dbo].[sp_Get_DBCR_FilesRecordsCount]       
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
      
      
--declare   @RecordCount2 nchar(10)    
declare   @WorkingStatus nchar(10)    
declare   @SourceID nchar(10)    


select  @RecordCount2 = COUNT(*),@WorkingStatus = WorkingStatus ,@SourceID= SourceID    
from StoreTransactions_Working      
where -- WorkingStatus=-1313 and      
1=1       
and WorkingSource in ('SUP-U','SUP-S')      
and SourceIdentifier = '401300.MSG'  
group by WorkingStatus,SourceID 
Print  @RecordCount2
 Print @SourceID 
 Print  @WorkingStatus  
     

      
--select @RecordCount3 = COUNT(*)      
--from DataTrue_Archive..StoreTransactions_Working      
--where -- WorkingStatus=-1313 and      
--1=1       
--and WorkingSource in ('SUP-U','SUP-S')      
--and SourceIdentifier = @FileName       
      
select 'FileName'= @FileName ,'EDIInbound846INVCount' = @RecordCount1, 'Main_StoreTxnCount' = @RecordCount2,'ArchiveCount' = @RecordCount3      
      
End
GO
