USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_SaveStoreAssociations]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[usp_SaveStoreAssociations]
    @StoreId varchar(20),
    @SupplierId varchar(20),
    @RouteNumber varchar(50),
    @DriverName varchar(50),
    @SupplierAccountNumber varchar(20),
    @SBTNumber varchar(20),
    @ShipToField varchar(20),
    @DistributionCenter varchar(20),
    @SalesRep varchar(50),
    @RegionalMgr varchar(50),
    @Comments varchar(200),
    @LastUpdateUserID varchar(20),
    @EditMode int
as
begin
    Declare @strSQL varchar(4000)
 
    if(@EditMode='0')
        Begin
            INSERT INTO [DataTrue_Main].[dbo].[StoresUniqueValues]
               ([StoreID]
               ,[SupplierID]
               ,[RouteNumber]
               ,[DriverName]
               ,[SupplierAccountNumber]
               ,[SBTNumber]
               ,[ShipToField]
               ,[DistributionCenter]
               ,[SalesRep]
               ,[RegionalMgr]
               ,[Comments]
               ,[DateTimeCreated]
               ,[LastUpdateUserID]
               ,[DateTimeLastUpdate])
            VALUES
               (@StoreId
               ,@SupplierId
               ,@RouteNumber
               ,@DriverName
               ,@SupplierAccountNumber
               ,@SBTNumber
               ,@ShipToField
               ,@DistributionCenter
               ,@SalesRep
               ,@RegionalMgr
               ,@Comments
               ,GETDATE()
               ,@LastUpdateUserID
               ,GETDATE())
                                                    
        End
    else if(@EditMode='1')
    Begin
        UPDATE [DataTrue_Main].[dbo].[StoresUniqueValues]
           SET
              [RouteNumber] = @RouteNumber
              ,[DriverName] = @DriverName
              ,[SupplierAccountNumber] = @SupplierAccountNumber
              ,[SBTNumber] = @SBTNumber
              ,[ShipToField] = @ShipToField
              ,[DistributionCenter] = @DistributionCenter
              ,[SalesRep] = @SalesRep
              ,[RegionalMgr] = @RegionalMgr
              ,[Comments] = @Comments
              ,[LastUpdateUserID] = @LastUpdateUserID
              ,[DateTimeLastUpdate] = GETDATE()
         WHERE [StoreID] = @StoreID and [SupplierID] = @SupplierId
         
          INSERT INTO [DataTrue_Main].[dbo].[StoresUniqueValues_History]
               ([StoreID]
               ,[SupplierID]
               ,[RouteNumber]
               ,[DriverName]
               ,[SupplierAccountNumber]
               ,[SBTNumber]
               ,[ShipToField]
               ,[DistributionCenter]
               ,[SalesRep]
               ,[RegionalMgr]
               ,[Comments]
               ,[DateTimeCreated]
               ,[LastUpdateUserID]
               ,[DateTimeLastUpdate])
            VALUES
               (@StoreId
               ,@SupplierId
               ,@RouteNumber
               ,@DriverName
               ,@SupplierAccountNumber
               ,@SBTNumber
               ,@ShipToField
               ,@DistributionCenter
               ,@SalesRep
               ,@RegionalMgr
               ,@Comments
               ,GETDATE()
               ,@LastUpdateUserID
               ,GETDATE())
    End  
   
       
end
GO
