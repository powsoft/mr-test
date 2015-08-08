USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[sp_SupplierTab2]    Script Date: 06/25/2015 18:26:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[sp_SupplierTab2]
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
   Set @strCondition ='where t1.storeId=t2.storeId ' 
  If Len(LTrim(@supplierId)) > 0
  Set @strCondition = @strCondition +'And t1.supplierId in (' + @supplierId + ')'
  
  
  If Len(LTrim(@strRetailerName)) > 0
   Set @strCondition = @strCondition + ' And  t2.chainid = (
select 
ChainId
from Chains where  ChainName='''+@strRetailerName+''')'
 
  If Len(LTrim(@strBannerId)) > 0
   Set @strCondition = @strCondition + 'And t2.custom1='''+@strBannerId+''''
 
    If  Len(LTrim(@dtpInvDate))> 0
   Set @strCondition = @strCondition + ' And  t1.physicalInventoryDate < =''' +@dtpInvDate+''''
   
   
  Set @strSql = 'select t1.*,sum( t1.invoiceamount) as invAmount 
from InventorySettlementRequests t1,stores t2 
 '+ @strCondition+' 
group by t1.InventorySettlementRequestID,  t1.storeId , t1.storeNumber, t1.physicalInventoryDate,
 t1.invoiceAmount, t1.settle, t1.UnsettledShrink, 
 t1.RequestingPersonID, t1.RequestDate,
 t1.ApprovingPersonID, t1.ApprovedDate,t1.supplierid,t1.retailerid,t1.DenialReason
order by  t1.storeid, t1.physicalInventoryDate desc'
 
delete from TempSupplierTab2;
 INSERT INTO TempSupplierTab2

EXEC (@strSql)

select * from TempSupplierTab2
  
 Set Nocount Off
End
GO
