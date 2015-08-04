USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetStoreDeliverySettings]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_GetStoreDeliverySettings]
	@ChainId varchar(20),
	@StoreName varchar(100),
	@StoreNumber varchar(100)
as 
Begin
set nocount on
	Declare @strSQL varchar(2000)
	
	set @strSQL  = ' select C.ChainName, S.StoreId, S.StoreName, S.StoreIdentifier as StoreNumber,  ReplenishmentFrequency, ReplenishmentType
					from Stores S
					inner join Chains C on C.ChainId=S.ChainId
					left join PlanogramStoreDeliveryDates D on D.StoreID=S.StoreID 
					Where S.ActiveStatus=''Active'''
	
	if(@ChainId<>'-1')
		set @strSQL = @strSQL +  ' and C.ChainId = ' + @ChainId
	
	if(@StoreNumber<>'')
		set @strSQL = @strSQL +  ' and S.StoreIdentifier like  ''%' + @StoreNumber + '%'''
		
	if(@StoreName<>'')
		set @strSQL = @strSQL +  ' and S.StoreName like  ''%' + @StoreName + '%'''
			
	exec(@strSQL)
End
GO
