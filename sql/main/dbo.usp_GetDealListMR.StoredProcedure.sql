USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetDealListMR]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_GetDealListMR]

 @SupplierId varchar(20),
 @ChainId varchar(20),
 @Banner varchar(500),
 @RequestTypeID Varchar(20)
as
-- exec [usp_GetDealListMR] '44269','44285','All','-1'

Begin

Declare @sqlQuery varchar(4000)

	set @sqlQuery = 'SELECT distinct DealNumber  
					from MaintenanceRequests  WITH(NOLOCK)  
					WHERE DealNumber is not null and DealNumber <>'''' '
 

	if(@ChainId <> '-1' and @ChainId <> '') 
		set @sqlQuery  = @sqlQuery  + ' and ChainId =' + @ChainId
                                                 
	if(@SupplierId <> '-1' and @SupplierId <> '')  
		set @sqlQuery = @sqlQuery + ' and SupplierId=' + @SupplierId 
					
	if(@Banner <> '-1' and @Banner <> '' and @Banner <> 'All') 
		set @sqlQuery = @sqlQuery + ' and Banner='''+ @Banner + ''''
		
	if(@RequestTypeID <> '-1' and @RequestTypeID <> '') 
		set @sqlQuery = @sqlQuery + ' and RequestTypeID='''+ @RequestTypeID + ''''
										
	set @sqlQuery = @sqlQuery + ' order by DealNumber '
	
exec(@sqlQuery); 
print (@sqlQuery); 
End
GO
