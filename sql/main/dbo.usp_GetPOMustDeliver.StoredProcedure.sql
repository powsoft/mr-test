USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetPOMustDeliver]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_GetPOMustDeliver]
@StoreSetUpID varchar(20)	
AS
--Select * from [PO_ MustDeliver]
--exec usp_GetPOMustDeliver '4102446' 
BEGIN
 DECLARE @strSQLQuery VARCHAR(4000)
 
Set @strSQLQuery='SELECT distinct Convert(varchar(10),StartDate,101)  as [MustDeliverStartDate],Convert(varchar(10),EndDate,101) as [MustDeliverEndDate],Convert(varchar,MustDeliver) as [MustDeliverUnits] from [PO_MustDeliver]'

Set @strSQLQuery= @strSQLQuery + ' Where 1=1	'	
 
set @strSQLQuery = @strSQLQuery +  ' and StoreSetUpID=' + @StoreSetUpID	

exec(@strSQLQuery)
print @strSQLQuery
 
END
GO
