USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[SupplierTab1]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SupplierTab1] 
(@supplierId varchar(50) ,
@strRetailerName varchar(100),
@strBannerId varchar(100),
@dtpInvDate varchar(100)
)
AS
Begin
 Set Nocount On
  Declare @strSql nVarchar(1000)
  Declare @strCondition nVarchar(300)
  
  Set @strCondition = 'Where t1.InventorySettlementId is null and t1.InvoiceDetailTypeID in(3,5,6,9,10)'
  If Len(LTrim(@supplierId)) > 0
   Set @strCondition = @strCondition +  ' And t1.supplierId in (' + @supplierId + ')'
  
  If Len(LTrim(@strRetailerName)) > 0
   Set @strCondition = @strCondition + ' And  t3.ChainName = '''+@strRetailerName+''''
  
   If Len(LTrim(@strBannerId)) > 0
   Set @strCondition = @strCondition + ' And t2.custom1='''+@strBannerId+''''
 
    If  Len(LTrim(@dtpInvDate))> 0
   Set @strCondition = @strCondition + ' And t1.SaleDate <=''' +@dtpInvDate+''''
   
   

  Set @strSql = 'select t1.StoreId,t2.StoreIdentifier,sum(t1.TotalCost) as invamount,t1.SaleDate,t1.ChainID,t1.supplierid
from InvoiceDetails t1,Stores t2,Chains t3 '+ @strCondition+'
 and t1.StoreId=t2.storeId and t2.chainId=t3.ChainID
 and CONVERT(VARCHAR(11),t1.StoreId)+CONVERT(VARCHAR(11),t1.SaleDate,101) not in
 (
 select CONVERT(VARCHAR(11),StoreId)+CONVERT(VARCHAR(11),physicalInventoryDate,101) from InventorySettlementRequests
 )
 group by t1.StoreId,t2.StoreIdentifier,t1.SaleDate ,t1.InventorySettlementId,t1.ChainID,t1.supplierid
 order by t1.storeid,t1.SaleDate desc'
 
 delete from InvenSupplierTab1;
 INSERT INTO InvenSupplierTab1

EXEC (@strSql)

select * from InvenSupplierTab1
 
 
 
End
GO
