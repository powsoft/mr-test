USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_GetChainList_Remittance]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--SELECT * from dbo.Manufacturers where ManufacturerIdentifier='DEFAULT'
--SELECT * from dbo.Suppliers where SupplierIdentifier='STC'
--exec [amb_GetChainList_Remittance] 'CLL','24164','-1','-1'
CREATE PROCEDURE [dbo].[amb_GetChainList_Remittance]
	@WholeSalerIdentifier nvarchar(100),
	@WholeSalerId nvarchar(100),
	@PublisherIdentifier nvarchar(100),
	@PublisherID nvarchar(100)
AS
BEGIN
	DECLARE @strSQL VARCHAR(1000)
	
	
	
	SET @strSQL=' SELECT distinct RR.ChainID  as ChainId
			, CL.ChainID as ChainName
		FROM [IC-HQSQL2].iControl.dbo.RemittanceReports  RR
		inner join [IC-HQSQL2].iControl.dbo.chainslist CL on RR.chainid=cl.chainid
		WHERE 1=1 and (((RR.WholesalerID)=''' + @WholeSalerIdentifier + '''))'

	SET @strSQL = @strSQL + ' UNION  '
	
	SET @strSQL = @strSQL + ' SELECT DISTINCT cast(C.ChainIdentifier as varchar) as ChainId, 
														cast(C.ChainIdentifier as varchar) as ChainName  
														FROM chains_migration CM
															INNER join dbo.Chains C ON CM.chainid=C.ChainIdentifier
															INNER JOIN dbo.storesetup SS ON SS.ChainID=C.ChainID	' 
	if(@PublisherID<>'-1')
		SET @strSQL = @strSQL + ' INNER JOIN dbo.Brands B ON SS.BrandID=B.BrandID
															INNER JOIN dbo.Manufacturers M ON M.ManufacturerID=B.ManufacturerID '
	
	--In case of publisher, we are binding the wholesaler drop down list with identifier only. so in this case we will send only identifier for the wholesaler and we will match identifier in the supplier table.
	IF(@WholeSalerId='-1' and @WholeSalerIdentifier<>'-1')
		SET @strSQL = @strSQL + ' INNER JOIN dbo.Suppliers Sup ON SS.Supplierid=Sup.Supplierid ' 
					
	SET @strSQL = @strSQL + '	WHERE 1=1 '
	
	
	IF(@WholeSalerId<>'-1')
		SET @strSQL = @strSQL + ' and SS.SupplierId=' + @WholeSalerId 
	else IF(@WholeSalerIdentifier<>'-1') --In case of publisher
		SET @strSQL = @strSQL + ' and Sup.SupplierIdentifier=''' + @WholeSalerIdentifier + ''''
	
	if(@PublisherID<>'-1')
		SET @strSQL = @strSQL + ' and M.ManufacturerID=' + @PublisherID 
	
	SET @strSQL = @strSQL + ' order by ChainName'
	
	EXEC (@strSQL)
	print @strSQL
END
GO
