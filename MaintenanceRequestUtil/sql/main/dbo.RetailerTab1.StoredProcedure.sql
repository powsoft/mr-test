USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[RetailerTab1]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[RetailerTab1] 

(@retailerId varchar(50) ,
@strSupplierName varchar(100),
@strBannerId varchar(100),
@strStatus varchar(100)
)
AS
Begin
 Set Nocount On
  Declare @strSql nVarchar(1000)
  Declare @strCondition nVarchar(300)
 
 Set @strCondition ='where t1.storeId =t2.storeId and t1.supplierID=t3.supplierId'
  
 
   If Len(LTrim(@retailerId)) > 0
   Set @strCondition = @strCondition +  ' And t1.retailerid in(' + @retailerId + ')'
 
  If Len(LTrim(@strSupplierName)) > 0
   Set @strCondition = @strCondition +  ' And t3.supplierName=''' + @strSupplierName + ''''
 
  If Len(LTrim(@strBannerId)) > 0
   Set @strCondition = @strCondition + ' And  t2.custom1 = '''+@strBannerId+''''
 
  
   If  @strStatus='Pending'
   Set @strCondition = @strCondition + ' And t1.ApprovedDate is null'
  
   If  @strStatus='Settled'
   Set @strCondition = @strCondition + ' And t1.Settle=''Y'' And t1.ApprovedDate is not null'
   
   If  @strStatus='Denied'
   Set @strCondition = @strCondition + ' And t1.Settle=''Denied'' And t1.ApprovedDate is not null'
   
  Set @strSql = 'select t1.*,sum(t1.invoiceamount) as invAmount
 from InventorySettlementRequests t1,Stores t2,Suppliers t3
 
 '+ @strCondition+'
  group by t1.InventorySettlementRequestID, t1.storeId ,t1.storeNumber,t1.physicalInventoryDate,
t1.invoiceAmount,t1.settle,t1.UnsettledShrink,
t1.RequestingPersonID,t1.RequestDate,
t1.ApprovingPersonID,t1.ApprovedDate,t1.supplierid,t1.retailerid,t1.DenialReason
order by t1.storeid,t1.physicalInventoryDate desc'
 
delete from TempSupplierTab2;
 INSERT INTO TempSupplierTab2

EXEC (@strSql)

select * from TempSupplierTab2

 
End
GO
