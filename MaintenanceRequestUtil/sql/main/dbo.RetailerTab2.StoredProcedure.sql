USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[RetailerTab2]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[RetailerTab2] 
(@retailerId varchar(50) ,
@strSupplierName varchar(100),
@strBannerId varchar(100))
AS
Begin
 Set Nocount On
  Declare @strSql nVarchar(1000)
  Declare @strCondition nVarchar(300)
  
 
  Set @strCondition = 'Where t1.InventorySettlementId is null '
  
  If Len(LTrim(@retailerId)) > 0
   Set @strCondition = @strCondition +  'And t1.chainId in (' + @retailerId + ')'
 
  If Len(LTrim(@strSupplierName)) > 0
   Set @strCondition = @strCondition +  'And t3.supplierName=''' + @strSupplierName + ''''
  
  
   If Len(LTrim(@strBannerId)) > 0
   Set @strCondition = @strCondition + 'And t2.custom1='''+@strBannerId+''''
 
  

  Set @strSql = 'select 
 t1.StoreId,t2.StoreIdentifier,sum(t1.TotalCost) as invamount,t1.SaleDate,t1.ChainID,t1.supplierid
from InvoiceDetails t1,Stores t2,Suppliers t3  '  + @strCondition+'
and t1.StoreId=t2.storeId and t1.SupplierId=t3.SupplierId  and t1.InvoiceDetailTypeID in (3,5,6,9,10)
 group by t1.StoreId,t2.StoreIdentifier,t1.SaleDate ,t1.InventorySettlementId,t1.ChainID,t1.supplierid
 order by t1.storeid,t1.SaleDate desc'
 
delete from InvenSupplierTab1;
 INSERT INTO InvenSupplierTab1

EXEC (@strSql)

select *from InvenSupplierTab1


 
 
 
End
GO
