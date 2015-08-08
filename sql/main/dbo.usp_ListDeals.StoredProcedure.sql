USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_ListDeals]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_ListDeals]
 @DealNumber varchar(50),
 @SupplierId varchar(10),
 @ChainId varchar(10),
 @Banner varchar(50)
as

Begin
 Declare @sqlQuery varchar(4000)
 set @sqlQuery = 'select DealNumber, convert(varchar(10),SubmitDateTime,101) as [SubmitDate], 
      PromoAllowance, convert(varchar(10),StartDateTime,101) as [StartDate], convert(varchar(10), EndDateTime, 101) as [EndDate], 
      isnull(MarkDeleted,0) as MarkDeleted
      from MaintenanceRequests where DealNumber is not null '

if(@DealNumber <>'-1') 
  set @sqlQuery  = @sqlQuery  + ' and DealNumber = ''' + @DealNumber + '''';

if(@ChainId <>'-1') 
  set @sqlQuery  = @sqlQuery  + ' and ChainId = ' + @ChainId ;
  
if(@SupplierId <>'-1') 
  set @sqlQuery  = @sqlQuery  + ' and SupplierId = ' + @SupplierId ;
  
if(@Banner <>'-1') 
 set @sqlQuery  = @sqlQuery  + ' and Banner = ''' + @Banner + '''';
 
    
set @sqlQuery  = @sqlQuery  + ' group by DealNumber, SubmitDateTime, PromoAllowance, StartDateTime, EndDateTime, markdeleted '

execute(@sqlQuery); 

End
GO
