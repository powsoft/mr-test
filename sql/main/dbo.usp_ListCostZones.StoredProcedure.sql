USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_ListCostZones]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_ListCostZones]
 
 @SupplierId varchar(20),
 @ChainId varchar(20)
 
as

Begin
	Declare @sqlQuery varchar(4000)
	
	set @sqlQuery = 'Select C.*, S.SupplierName from CostZones C inner Join Suppliers S on S.SupplierId=C.SupplierId WHERE 1=1 '
 
	if(@SupplierId<>'-1')
		set @sqlQuery = @sqlQuery + ' and S.SupplierId=' + @SupplierId
 
	if(@ChainId<>'-1')
		set @sqlQuery = @sqlQuery + ' and S.SupplierId in (Select distinct SupplierId from StoreSetup where ChainId=' + @ChainId + ')'

	set @sqlQuery = @sqlQuery + ' order by 1,2 '

	execute(@sqlQuery); 

End
GO
