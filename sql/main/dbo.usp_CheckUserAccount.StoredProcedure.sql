USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_CheckUserAccount]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_CheckUserAccount]
 @UserName varchar(200),
 @UserType varchar(20)
as

Begin
 Declare @sqlQuery varchar(4000)
 
 set @sqlQuery = 'Select * from Logins WHERE Login =''' + @UserName + ''''
 if(@UserType = 'Admin') 
    set @sqlQuery = @sqlQuery + ' and Login in (
                                    ''sean.zlotnitsky@icontroldsd.com'',
                                    ''bill.harris@icontroldsd.com'',
                                    ''judy.farniok@icontroldsd.com'',
                                    ''brendan.bannon@icontroldsd.com'',
                                    ''vishal@amebasoftwares.com'',
                                    ''mark.alguire@icontroldsd.com'',
                                    ''mike.flebotte@icontroldsd.com'',
                                    ''stephanie.scheftner@icontroldsd.com'',
                                    ''gilad.keren@icontroldsd.com'')'
 else if(@UserType = 'Gopher') 
    set @sqlQuery = @sqlQuery + ' and Login in (
                                    ''sean.zlotnitsky@icontroldsd.com'',
                                    ''jls@gophernews.com'',
                                    ''san@gophernews.com'',
                                    ''jpa@gophernews.com'',
                                    ''mac@gophernews.com'',
                                    ''vishal@amebasoftwares.com'',
                                    ''jlw@gophernews.com'')'
                                  
 
else if(@UserType = 'iControl') 
    set @sqlQuery = @sqlQuery + ' and OwnerEntityId in (Select distinct OwnerEntityId from AttributeValues where AttributeID=18)'
                                                                        
exec (@sqlQuery);

End

--exec [usp_CheckUserAccount] 'Stephanie.Scheftner@icontroldsd.com','admin'
GO
