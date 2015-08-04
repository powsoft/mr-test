USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[InboundInventory_Web_Save]    Script Date: 06/25/2015 18:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[InboundInventory_Web_Save]
@ChainName varchar(50),
@PurposeCode varchar(20),
@StoreNumber varchar(50),
@Qty decimal(10,2),
@Retail decimal(10,2),
@EffectiveDate datetime,
@ItemNumber varchar(50),
@FileName varchar(50),
@InvoiceDueDate datetime,
@DataTrueChainID varchar(50),
@DataTrueStoreID varchar(50),
@DataTrueProductID varchar(50),
@DataTrueBrandID varchar(50),
@DataTrueSupplierID varchar(50),
@LastUpdateUserID int
as  
begin
 insert into [DataTrue_EDI].[dbo].[InboundInventory_Web] ([ChainName],[PurposeCode],[StoreNumber],[Qty],[Retail],[EffectiveDate],[ItemNumber],[FileName],[InvoiceDueDate],[DataTrueChainID],[DataTrueStoreID],[DataTrueProductID],[DataTrueBrandID],[DataTrueSupplierID],[DateTimeCreated],[LastUpdateUserID]) values (@ChainName,@PurposeCode,@StoreNumber,@Qty,@Retail,@EffectiveDate,@ItemNumber,@FileName,@InvoiceDueDate,@DataTrueChainID,@DataTrueStoreID,@DataTrueProductID,@DataTrueBrandID,@DataTrueSupplierID,GETDATE(),@LastUpdateUserID)
 end
GO
