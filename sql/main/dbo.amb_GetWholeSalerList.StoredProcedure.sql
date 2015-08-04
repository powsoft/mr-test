USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_GetWholeSalerList]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec [amb_GetWholeSalerList] '-1','-1',1,'DOWJ','35321'
CREATE PROCEDURE [dbo].[amb_GetWholeSalerList]
    @ChainIdentifier NVARCHAR(100) ,
    @ChainId NVARCHAR(100) ,
    @ChainMigrated VARCHAR(1), --0 for Old DB, 1 for New DB, 2 for Both 
    @PublisherIdentifier nvarchar(100),
	@PublisherID nvarchar(100)
AS 
  BEGIN
		DECLARE @strSQLOld VARCHAR(1000)
		DECLARE @strSQLNew VARCHAR(1000)
		DECLARE @strSQLAdminNew VARCHAR(1000)
		
    
    IF(@ChainMigrated=2 or @ChainMigrated=0)
			BEGIN
				SET @strSQLOld = ' SELECT DISTINCT cast(W.WholeSalerID as varchar) as SupplierID, 
						W.WholeSalerName AS SupplierName  
						FROM [IC-HQSQL2].iControl.dbo.Wholesalerslist W 
						INNER JOIN [IC-HQSQL2].iControl.dbo.BaseOrder B ON B.WholeSalerID=W.WholeSalerID '
				
				IF ( @PublisherIdentifier <> '-1' ) 		
						SET @strSQLOld = @strSQLOld + ' INNER JOIN [IC-HQSQL2].iControl.dbo.Products P on P.BiPad = B.BiPad'
				
				SET @strSQLOld = @strSQLOld + ' Where 1=1 and W.active=1 '
						
				IF ( @PublisherIdentifier <> '-1' )
					SET @strSQLOld = @strSQLOld + ' and P.PublisherID=''' + @PublisherIdentifier + ''''
							
				IF ( @ChainIdentifier <> '-1' ) 
						SET @strSQLOld = @strSQLOld + ' and  B.ChainId='+@ChainIdentifier	
			END
    IF(@ChainMigrated=2 )    
      BEGIN
				SET @strSQLNew = ' SELECT DISTINCT cast(S.SupplierIdentifier as varchar) as SupplierID, 
						S.SupplierName AS SupplierName  
						FROM DataTrue_Report.dbo.Suppliers S 
						INNER JOIN DataTrue_Report.dbo.StoreTransactions ST ON ST.SupplierID=S.SupplierID
						JOIN Chains c ON ST.ChainID=c.ChainID
						inner JOIN chains_migration cm ON ltrim(rtrim(cm.chainid))=ltrim(rtrim(c.ChainIdentifier))
						WHERE S.ActiveLastDate>GETDATE()'
					
				IF ( @ChainId <> '-1' ) 
						SET @strSQLNew = @strSQLNew + ' and  ST.ChainId='+@ChainId	
			END
		IF( @ChainMigrated=1)
			BEGIN
				SET @strSQLAdminNew = ' SELECT DISTINCT cast(S.SupplierIdentifier as varchar) as SupplierID, 
						S.SupplierName AS SupplierName  
						FROM DataTrue_Report.dbo.Suppliers S 
						INNER JOIN  DataTrue_Report.dbo.StoreTransactions ST ON ST.SupplierID=S.SupplierID
						WHERE S.ActiveLastDate>GETDATE()'
					
				IF ( @ChainId <> '-1' ) 
						SET @strSQLAdminNew = @strSQLAdminNew + ' and  ST.ChainId='+@ChainId	
			END
	

		if(@ChainMigrated=2)
				exec (@strSQLOLD +' Union ' +@strSQLNEW+ ' ORDER BY 2')
				--print (@strSQLOLD +' Union ' +@strSQLNEW+ ' ORDER BY 2')
		else if(@ChainMigrated=0)
				exec (@strSQLOLD +' ORDER BY 2')
		else if(@ChainMigrated=1)
				exec (@strSQLAdminNew+' ORDER BY 2')
				 
	END
GO
