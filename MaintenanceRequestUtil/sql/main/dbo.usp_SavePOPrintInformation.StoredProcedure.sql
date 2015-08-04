USE [DataTrue_Main]
GO
/****** Object:  StoredProcedure [dbo].[usp_SavePOPrintInformation]    Script Date: 06/25/2015 18:26:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec usp_SavePOPrintInformation '06/18/2012', 40557, 40365, 15
CREATE  Procedure [dbo].[usp_SavePOPrintInformation]
     @SupplierId varchar(50),
     @StoreId varchar(50),
     @PODate varchar(50)
     
as
begin

	Declare @PuchaseOrderNo numeric(10)
    Declare @PuchaseOrderBeginNo numeric(10)
    
    Select @PuchaseOrderNo = ([PuchaseOrderNo]) from [PO_PrintInformation] where SupplierId=@SupplierId and StoreId=@StoreId and PODate=@PODate
    
    if(@PuchaseOrderNo is null)
		Select @PuchaseOrderNo = MAX([PuchaseOrderNo]) + 1 	from [PO_PrintInformation] where SupplierId=@SupplierId
	else
		Begin
			Delete from [PO_PrintInformation] where PuchaseOrderNo=@PuchaseOrderNo
			Delete from [PO_PrintDetails] where PuchaseOrderNo=@PuchaseOrderNo
		End
	
	Select @PuchaseOrderBeginNo = [POBeginFrom] from [PO_PrintSettings]  where SupplierId=@SupplierId

	if(@PuchaseOrderNo is null or @PuchaseOrderNo < @PuchaseOrderBeginNo)           
		set @PuchaseOrderNo =@PuchaseOrderBeginNo
						
    INSERT INTO [DataTrue_Main].[dbo].[PO_PrintInformation]
           ([PuchaseOrderNo]
           ,[PODate]
           ,[SupplierId]
           ,[StoreId]
           )
     VALUES
           (@PuchaseOrderNo
           ,@PODate
           ,@SupplierId
           ,@StoreId
           )
    
    select @PuchaseOrderNo
end
GO
