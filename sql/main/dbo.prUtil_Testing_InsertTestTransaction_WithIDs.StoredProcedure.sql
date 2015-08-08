USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Testing_InsertTestTransaction_WithIDs]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[prUtil_Testing_InsertTestTransaction_WithIDs]
     @ChainId int,
     @StoreId int,
     @SourceId int,
     @SupplierId int,
     @Qty int,
     @SaleDateTime datetime,
     @ProductID int,
     @brandid int,
     @ReportedCost money,
     @ReportedRetail money,
     @LastUpdateUserID int,
     @WorkingSource nvarchar(50),
     @productidentifier nvarchar(50)
/*
     @ChainIdentifier nvarchar(50),
     @StoreIdentifier nvarchar(50),
     @SourceIdentifier nvarchar(50),
     @SupplierIdentifier nvarchar(50),
     @Qty int,
     @SaleDateTime datetime,
     @UPC nvarchar(50),
     @ReportedCost money,
     @ReportedRetail money,
     @LastUpdateUserID int,
     @WorkingSource nvarchar(50)
     */
as

INSERT INTO [DataTrue_Main].[dbo].[StoreTransactions_Working]
           ([ChainId]
           ,[StoreId]
           ,[SourceId]
           ,[SupplierId]
           ,[Qty]
           ,[SaleDateTime]
           ,[ProductID]
           ,[BrandID]
           ,[ReportedCost]
           ,[ReportedRetail]
           ,[LastUpdateUserID]
           ,[WorkingSource]
           ,[WorkingStatus]
           ,[StoreIdentifier]
           ,[UPC])
     VALUES
           (@ChainId,
			@StoreId,
			@SourceId,
			@SupplierId,
			@Qty,
			@SaleDateTime,
			@ProductID,
			@brandid,
			@ReportedCost,
			@ReportedRetail,
			@LastUpdateUserID,
			@WorkingSource,
			4, --WorkingStatus
			'', --storeidentifier
			@productidentifier)

return
GO
