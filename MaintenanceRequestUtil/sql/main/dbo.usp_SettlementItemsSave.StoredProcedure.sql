USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_SettlementItemsSave]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[usp_SettlementItemsSave] 
     @InventorySettlementRequestID int output,
     @StoreNumber nvarchar(50) ,
     @StoreID int ,
     @PhysicalInventoryDate datetime ,
     @InvoiceAmount money ,
     @TotalQty int ,
     @Settle varchar(50) ,
     @UnsettledShrink money ,
     @RequestingPersonID int ,
     @RequestDate datetime ,
     @supplierId int,
     @RetailerId int,
     @UPC varchar(50), 
     @ProductId int ,
     @FinalInvoiceTotalCost money
      as

if (@InventorySettlementRequestID = 0)

begin


      Insert into [InventorySettlementRequests] (
        [StoreNumber]  ,
        [StoreID]  ,
        [PhysicalInventoryDate]  ,
        [InvoiceAmount]  ,
        [TotalQty]  ,
        [Settle]  ,
        [UnsettledShrink]  ,
        [RequestingPersonID]  ,
        [RequestDate]  ,
        [supplierId]  ,
        [RetailerId],
        [UPC],
        [ProductId],
        [FinalInvoiceTotalCost]
           )
      Values(
        @StoreNumber  ,
        @StoreID  ,
        @PhysicalInventoryDate  ,
        @InvoiceAmount  ,
        @TotalQty  ,
        @Settle  ,
        @UnsettledShrink  ,
        @RequestingPersonID  ,
        @RequestDate  ,
        @supplierId ,
        @RetailerId,
        @UPC,
        @ProductId ,
        @FinalInvoiceTotalCost
           )
       
        update InvoiceDetails set InventorySettlementID = @@IDENTITY where StoreID = @StoreID and SaleDate = @PhysicalInventoryDate and InvoiceDetailTypeID in (3,5,9,10) and ProductID=@ProductId
end

if (@InventorySettlementRequestID > 0)
Begin

     Update [InventorySettlementRequests] Set
     [StoreNumber] =  @StoreNumber ,
     [StoreID] =  @StoreID ,
     [PhysicalInventoryDate] =  @PhysicalInventoryDate ,
     [InvoiceAmount] =  @InvoiceAmount ,
     [TotalQty] =  @TotalQty ,
     [Settle] =  @Settle ,
     [UnsettledShrink] =  @UnsettledShrink ,
     [RequestingPersonID] =  @RequestingPersonID ,
     [RequestDate] =  @RequestDate ,
     [supplierId] =  @supplierId ,
     [RetailerId] = @RetailerId  ,
     [UPC] =  @UPC, 
     [ProductId] =  @ProductId ,
     [FinalInvoiceTotalCost] = @FinalInvoiceTotalCost
     where [InventorySettlementRequestID] = @InventorySettlementRequestID
End
Declare @iErrorCode as int
-- Get the Error Code for the statement just executed.
SELECT @iErrorCode=@@ERROR
GO
