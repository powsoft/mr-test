USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetFieldValue]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_GetFieldValue]
@FldName varchar(1000),
@TableName varchar(2000)
as
-- exec usp_GetFieldValue 'C.PDITradingPartner','Chains C  WHERE C.ChainID=79370'
begin
DECLARE @sql varchar(5000)

set @sql ='select '+ @FldName +' as fld from '+ @TableName

PRINT(@sql)
EXEC(@sql)

end
GO
