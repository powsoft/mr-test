USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetChainList_PDI]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_GetChainList_PDI]
@ManufacturerId varchar(50),
 @ChainId varchar(20),
 @SupplierId varchar(20),
 @BannerName varchar(500)
as
-- exec [usp_GetChainList_PDI] '','','79891','D&W,Davis Oil,Family Fare,Valu Land,VG''''s,Xpress Mart'

Begin

Declare @sqlQuery varchar(4000)
	set @sqlQuery = 'Select distinct C.ChainId, C.ChainName from Chains C with (nolock) where 1 = 1 and chainId<>0'
	set @sqlQuery = @sqlQuery + ' and C.PDITradingPartner=1 order by C.ChainName '
	
exec(@sqlQuery); 
print (@sqlQuery); 
End
GO
