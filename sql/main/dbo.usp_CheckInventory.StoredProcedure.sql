USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_CheckInventory]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_CheckInventory]

@SupplierId varchar(10),
@ChainId varchar(10),
@BannerName varchar(255),
@StoreNo varchar(20),
@UPC varchar(50),
@RecordCount varchar(3)
as

Begin

begin try
        Drop Table [@tmpStoreSetup]
end try
begin catch
end catch

Declare @sqlQuery varchar(4000)

set @sqlQuery = ' select distinct SupplierID, StoreID, ProductID into [@tmpStoreSetup] from StoreSetup where 1=1 '

if(@SupplierId<>'-1')
    set @sqlQuery = @sqlQuery + ' and SupplierId =' + @SupplierId
 
exec (@sqlQuery)


set @sqlQuery = 'SELECT top ' + @RecordCount + ' P.ProductName as [Product Name], '

	if(@StoreNo='')
			set @sqlQuery = @sqlQuery + ' count(S.StoreIdentifier) as [Store Count], '
	else
			set @sqlQuery = @sqlQuery + ' (S.StoreIdentifier) as [Store No], '
	
	set @sqlQuery = @sqlQuery + '	sum(IP.CurrentOnHandQty)  AS [Qty Available]

	FROM  InventoryPerpetual IP

	INNER JOIN  dbo.ProductIdentifiers PD ON IP.ProductID = PD.ProductID AND PD.ProductIdentifierTypeID =2
	INNER JOIN  dbo.Products P ON PD.ProductID = P.ProductID
	INNER JOIN  dbo.Stores S ON IP.StoreID = S.StoreID and S.ActiveStatus=''Active''
	INNER JOIN  dbo.Chains C ON C.ChainID = S.ChainID
	LEFT Outer JOIN  [@tmpStoreSetup] SS on SS.StoreID =IP.StoreID and SS.ProductID =IP.ProductID 

	WHERE  1=1 '


if(@SupplierId<>'-1')
    set @sqlQuery = @sqlQuery + ' and SS.SupplierId =' + @SupplierId

if(@ChainId<>'-1')
    set @sqlQuery = @sqlQuery + ' and C.ChainId=' + @ChainId

if(@BannerName<>'-1')
    set @sqlQuery = @sqlQuery + ' and S.Custom1  = ''' + @BannerName + ''''

if(@UPC<>'')
    set @sqlQuery = @sqlQuery + ' and PD.IdentifierValue like ''%' + @UPC + '%'''

if(@StoreNo<>'')
    set @sqlQuery = @sqlQuery + ' and S.StoreIdentifier like ''%' + @StoreNo + '%'''

set @sqlQuery = @sqlQuery + '  group by P.ProductName '

if(@StoreNo<>'')
	set @sqlQuery = @sqlQuery + '  , S.StoreIdentifier '
	
exec(@sqlQuery);
print (@sqlQuery)
End
GO
