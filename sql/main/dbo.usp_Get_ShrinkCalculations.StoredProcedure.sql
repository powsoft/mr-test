USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_Get_ShrinkCalculations]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_Get_ShrinkCalculations]
 @ChainId varchar(10),
 @SupplierID varchar(10),
 @InvtCountTime varchar(20),
 @InvtCount varchar(20)
 
 as
Begin
 -- exec usp_Get_ShrinkCalculations '40393','-1','2','2'
Declare @sqlQuery varchar(1000) 
 
	set @sqlQuery = 'select S.SupplierName, C.ChainName, case when I.InventoryTakenBeginOfDay =1 then ''Beginning of Day'' 
					else ''End of Day'' end as [Inventory Count Time],
					case when I.InventoryTakenBeforeDeliveries =1 then ''Before Deliveries'' else ''After Deliveries'' end as [Inventory Counted]
						from InventoryRulesTimesBySupplierID I
						inner join Suppliers S on S.SupplierId=I.SupplierId
						inner join Chains C on C.ChainId=I.ChainId where 1=1 '
						
	if(@ChainId <>'-1')
                set @sqlQuery = @sqlQuery +  ' and C.ChainID=' + @ChainId
         
    if(@SupplierID <>'-1')
                set @sqlQuery = @sqlQuery +  ' and S.SupplierId=' + @SupplierId		
                
    if(@InvtCountTime <>'-1')
                set @sqlQuery = @sqlQuery +  ' and I.InventoryTakenBeginOfDay=' + @InvtCountTime	
                
    if(@InvtCount <>'-1')
                set @sqlQuery = @sqlQuery +  ' and I.InventoryTakenBeforeDeliveries=' + @InvtCount	                        
               
 exec(@sqlQuery);
 
End
GO
