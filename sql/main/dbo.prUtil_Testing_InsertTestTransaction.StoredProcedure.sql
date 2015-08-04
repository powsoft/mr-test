USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[prUtil_Testing_InsertTestTransaction]    Script Date: 06/25/2015 18:26:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[prUtil_Testing_InsertTestTransaction]
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

as

INSERT INTO [DataTrue_Main].[dbo].[StoreTransactions_Working]
           ([ChainIdentifier]
           ,[StoreIdentifier]
           ,[SourceIdentifier]
           ,[SupplierIdentifier]
           ,[Qty]
           ,[SaleDateTime]
           ,[UPC]
           ,[ReportedCost]
           ,[ReportedRetail]
           ,[LastUpdateUserID]
           ,[WorkingSource])
     VALUES
           (@ChainIdentifier,
			@StoreIdentifier,
			@SourceIdentifier,
			@SupplierIdentifier,
			@Qty,
			@SaleDateTime,
			@UPC,
			@ReportedCost,
			@ReportedRetail,
			@LastUpdateUserID,
			@WorkingSource)

return
GO
