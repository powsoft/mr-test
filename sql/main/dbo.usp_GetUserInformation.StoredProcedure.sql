USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetUserInformation]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_GetUserInformation]
@Login nvarchar(100),
@Password nvarchar(50)

as

Begin
 Declare @sqlQuery varchar(4000)

 set @sqlQuery = 'select (P.FirstName + '' '' +  P.LastName) as LoginName,P.PersonID, 
				case when PA.AttributeID=9 then 
					(Select SupplierName from Suppliers where SupplierID=PA.ChainIDOrSupplierID) 
				else 
					(Select ChainName from Chains where ChainId=PA.ChainIDOrSupplierID) 
				End as BusinessName, PA.AttributeID, PA.ChainIDOrSupplierID from Logins L
				inner join Persons P on P.PersonID=L.OwnerEntityId
				inner join PersonsAssociation PA on  P.PersonID=PA.PersonID 
                WHERE  1=1'

 if(@Login<>'')
    set @sqlQuery = @sqlQuery +  ' and L.Login=''' + @Login + ''''
 else
	set @sqlQuery = @sqlQuery +  ' and L.Login=''BLANK'''
 
 if(@Password<>'')
    set @sqlQuery = @sqlQuery +  ' and L.Password=''' + @Password  + ''''
 else
	set @sqlQuery = @sqlQuery +  ' and L.Password=''BLANK'''
	
 Exec(@sqlQuery);

End
GO
