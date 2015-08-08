USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[amb_ViewAndDownloadRemittancesWHL]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- EXEC [amb_ViewAndDownloadRemittancesWHL] 'CLL','DQ','-1'
CREATE procedure [dbo].[amb_ViewAndDownloadRemittancesWHL]
(
	@uname varchar(20),
	@Chain varchar(20),
	@CheckNumber varchar(20)
)

as 
BEGIN

DECLARE @sqlQuery VARCHAR(4000)

      
	SET @sqlQuery  = ' Select 
					   FileLocation= REVERSE(LEFT(REVERSE(FileLocation),CHARINDEX(''\'',reverse(FileLocation),1)-1)),
					   FileLocation as CompletePath,
					   CheckNumber,C.ChainIdentifier as ChainID
					   ,''Harmony'' as dbtype
					   From  RemittanceReports RR with (nolock) 
					   inner JOIN dbo.Chains C  with (nolock) on C.ChainID=RR.chainid
					   inner join PaymentDisbursements D on D.CheckNo=RR.CheckNumber and D.VoidStatus is null
						 inner JOIN chains_migration CM  with (nolock) on CM.ChainID=C.ChainIdentifier
						 inner join dbo.suppliers S  with (nolock)  on s.SupplierID=rr.WholesalerID
					   WHERE 1=1  AND s.SupplierIdentifier='''+@uname+''''
					   
	IF(@CheckNumber<>'-1') 
		 SET @sqlQuery += ' AND RR.CheckNumber like ''%'+@CheckNumber+'%''' 
		 
	IF(@Chain<>'-1') 	 
		  SET @sqlQuery += ' AND  C.ChainIdentifier = '''+@Chain+''''
		 
		 
		print @sqlQuery
    EXEC(@sqlQuery)		  
					  				
 End
GO
