USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_NonSharedShrinkUsers]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create procedure [dbo].[usp_NonSharedShrinkUsers]
 @SupplierId varchar(20)
as

Begin
 Declare @sqlQuery varchar(4000)
 set @sqlQuery = 'Select * from Suppliers WHERE SupplierId not in (40578, 40569, 41460, 41463, 40563) '

 if(@SupplierId <>'-1') 
	set @sqlQuery = @sqlQuery + ' and SupplierId = ''' + @SupplierId + ''''
   
execute(@sqlQuery); 

End
GO
