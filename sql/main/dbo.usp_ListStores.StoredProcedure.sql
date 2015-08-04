USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_ListStores]    Script Date: 06/25/2015 18:26:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_ListStores]
 
 @StoreNumber varchar(50),
 @SBTNumber varchar(50),
 @BannerID varchar(30),
 @City Varchar(50)
as

Begin
 Declare @sqlQuery varchar(4000)
 set @sqlQuery = 'Select *, case when DATEDIFF("d",openingdate, GETDATE())<=7 
					then 1 else 0 end as Editable 
					from CreateStores WHERE 1=1 '

 if(@StoreNumber <>'') 
  set @sqlQuery  = @sqlQuery  + ' and StoreNumber like ''%' + @StoreNumber + '%''';

 if(@SBTNumber <> '') 
  set @sqlQuery = @sqlQuery + ' and sbtnumber like ''%' + @SBTNumber + '%''';

 if(@BannerID <>'-1') 
  set @sqlQuery = @sqlQuery + ' and Banner = ''' + @BannerID + ''''
  
 if(@City <>'') 
  set @sqlQuery = @sqlQuery + ' and city  like ''%' + @City  + '%''';
 
 
execute(@sqlQuery); 

End
GO
