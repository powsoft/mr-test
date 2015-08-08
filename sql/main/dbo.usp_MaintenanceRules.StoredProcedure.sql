USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_MaintenanceRules]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_MaintenanceRules]
@ChainId varchar(10),
@SupplierID varchar(10),
@ClusterID varchar(10),
@CategoryID varchar(50),
@RequestTypeID varchar(10),
@LeadTime varchar(50)
-- [usp_MaintenanceRules] '59973','-1','-1','-1','-1',''
as

Begin

Declare @sqlQuery varchar(4000)

	set @sqlQuery = 'SELECT MR.MRId,C.ChainName,
					case when MR.SupplierID=-1 then ''All'' else S.SupplierName end as SupplierName,
					case when MR.ClusterID=-1 then ''All'' else CL.ClusterName end as ClusterName,
					case when MR.CategoryID=-1 then ''All'' else PC.ProductCategoryName end as ProductCategoryName,MR.RequiredLeadTime,
					CASE WHEN MR.RequestTypeID = 1 THEN ''New Item'' 
					WHEN MR.RequestTypeID = 2 THEN ''Cost Change'' 
					WHEN MR.RequestTypeID = 3 THEN ''Promo'' 
					WHEN MR.RequestTypeID = 15 THEN ''Substitution/Replacement''
					WHEN MR.RequestTypeID = 9 THEN ''Delete/Deauthorized''
					WHEN MR.RequestTypeID = 14 THEN ''Discontinue''
					ELSE '''' END AS Activity
						FROM MaintenanceRules MR
						INNER JOIN Chains C ON C.ChainID=MR.ChainID
						INNER JOIN Suppliers S on S.SupplierID=MR.SupplierID
						Left JOIN Clusters CL ON CL.ClusterID=MR.ClusterID
						Left JOIN ProductCategories PC ON PC.ProductCategoryID=MR.CategoryID 
						WHERE 1=1 '
                 
    if(@ChainId<>'-1')
        set @sqlQuery = @sqlQuery + ' and C.ChainId=' + @ChainId
        
    if(@SupplierID<>'-1')
        set @sqlQuery = @sqlQuery + ' and S.SupplierID=' + @SupplierID     

    if(@ClusterID<>'-1')
        set @sqlQuery = @sqlQuery + ' and CL.ClusterID=' + @ClusterID

    if(@CategoryID<>'-1')
        set @sqlQuery = @sqlQuery + ' and PC.ProductCategoryID=' + @CategoryID 
        
    if (@RequestTypeID<>'-1')
		set @sqlQuery+= ' and MR.RequestTypeID = ' + @RequestTypeID

    if(@LeadTime<>'')
        set @sqlQuery = @sqlQuery + ' and MR.RequiredLeadTime=' + @LeadTime 

    EXEC(@sqlQuery)
End
GO
