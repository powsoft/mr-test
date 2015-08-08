USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetACHFiltersDetail]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- usp_GetACHFiltersDetail '-1','-1','-1','-1'
CREATE procedure [dbo].[usp_GetACHFiltersDetail]
 @SupplierId varchar(20),
 @ChainId varchar(20),
 @State varchar(50),
 @ACHFilterTypeID varchar(50)
 
as

Begin
Declare @sqlQuery varchar(4000)

	set @sqlQuery = ' SELECT S.SupplierName AS [Supplier Name],C.ChainName as [Retailer Name],ACH.State,
						FT.ACHFilterTypeName as [ACH Filter Type],ACH.ACHFilterValue as [ACH Filter Value],ACH.ACHFilterID
						
					  From  dbo.ACHFilters ACH
						Inner Join dbo.ACHFilterTypes FT ON ACH.ACHFilterTypeId=FT.ACHFilterTypeId
						Inner Join dbo.Chains C ON C.ChainId=ACH.ChainID
						Inner Join dbo.Suppliers S ON S.SupplierID=ACH.SupplierID '



	set @sqlQuery  = @sqlQuery  + ' WHERE 1=1 '
		
	if(@ChainId <>'-1' ) 
		set @sqlQuery = @sqlQuery + ' and C.ChainID = ' + @ChainId  

    if(@SupplierId <>'-1' ) 
		set @sqlQuery = @sqlQuery + ' and S.SupplierID = ' + @SupplierId 
		
	if(@State <> '-1') 
		set @sqlQuery = @sqlQuery + ' and ACH.State = ''' + @State + ''''
		
	if(@ACHFilterTypeID <>'-1') 
		set @sqlQuery = @sqlQuery + ' and ACH.ACHFilterTypeId  = ' + @ACHFilterTypeID

    
    set @sqlQuery = @sqlQuery + ' order by 1,2,3 asc '

	exec(@sqlQuery); 

End
GO
